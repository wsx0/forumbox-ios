import UIKit
import WebKit

/// 聚合搜索：在隐藏 WebView 中打开各论坛搜索页，抓取结果后合并
final class SearchAggregator {

    struct SiteResult {
        let site: Site
        var status: String
        var items: [(title: String, url: String)]
    }

    private var pendingSites: [Site] = []
    private var activeTasks: [SearchTask] = []
    private var activeCount = 0
    private var query = ""
    private var updateBlock: ((SiteResult) -> Void)?
    private var finishBlock: (() -> Void)?
    private var isCancelled = false

    private let maxConcurrent = 2

    deinit {
        cancel()
    }

    func cancel() {
        isCancelled = true
        pendingSites.removeAll()
        activeTasks.forEach { $0.cancel() }
        activeTasks.removeAll()
        activeCount = 0
        updateBlock = nil
        finishBlock = nil
    }

    func search(query: String,
                sites: [Site],
                update: @escaping (SiteResult) -> Void,
                finished: @escaping () -> Void) {
        cancel()
        isCancelled = false
        self.query = query
        self.updateBlock = update
        self.finishBlock = finished
        pendingSites = sites.filter { $0.searchURL != nil }
        guard !pendingSites.isEmpty else {
            finished()
            return
        }
        startNext()
        startNext()
    }

    private func startNext() {
        guard !isCancelled else { return }
        if pendingSites.isEmpty {
            if activeCount == 0 {
                let block = finishBlock
                finishBlock = nil
                block?()
            }
            return
        }
        guard activeCount < maxConcurrent else { return }

        let site = pendingSites.removeFirst()
        activeCount += 1
        let task = SearchTask(site: site, query: query) { [weak self] result in
            guard let self = self else { return }
            self.activeCount -= 1
            self.updateBlock?(result)
            self.activeTasks.removeAll { $0.isFinished }
            self.startNext()
        }
        activeTasks.append(task)
        task.start()
    }
}

/// 单个站点的搜索抓取任务
final class SearchTask: NSObject, WKNavigationDelegate {

    private let site: Site
    private let query: String
    private let webView: WKWebView
    private let onDone: (SearchAggregator.SiteResult) -> Void
    private var finished = false
    private var retries = 0
    private var timeoutTimer: Timer?

    var isFinished: Bool { return finished }

    init(site: Site, query: String, onDone: @escaping (SearchAggregator.SiteResult) -> Void) {
        self.site = site
        self.query = query
        self.onDone = onDone

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()   // 复用登录态/Cookie
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        config.userContentController.addUserScript(
            WKUserScript(source: WebScripts.popupSuppressor,
                         injectionTime: .atDocumentStart,
                         forMainFrameOnly: false))
        config.userContentController.addUserScript(
            WKUserScript(source: WebScripts.autoSearch,
                         injectionTime: .atDocumentEnd,
                         forMainFrameOnly: true))
        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 390, height: 800), configuration: config)

        super.init()
        self.webView.customUserAgent = UserAgents.mobileSafari
        self.webView.navigationDelegate = self
    }

    func start() {
        guard let searchURL = site.searchURL, !searchURL.isEmpty else {
            finish(status: "无搜索入口", items: [])
            return
        }
        var target = searchURL
        if let encoded = query.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            target = searchURL + "#fbq=" + encoded
        }
        guard let url = URL(string: target) else {
            finish(status: "地址无效", items: [])
            return
        }
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { [weak self] _ in
            self?.finish(status: "超时", items: [])
        }
        webView.load(URLRequest(url: url))
    }

    func cancel() {
        finished = true
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        webView.stopLoading()
        webView.navigationDelegate = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        scheduleExtract(after: 1.8)
    }

    private func scheduleExtract(after seconds: Double) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.extract()
        }
    }

    private func extract() {
        guard !finished else { return }
        let url = webView.url?.absoluteString.lowercased() ?? ""
        if url.contains("login") || url.contains("logging") || url.contains("member.php") {
            finish(status: "需要登录", items: [])
            return
        }
        webView.evaluateJavaScript(WebScripts.extractResults) { [weak self] result, _ in
            guard let self = self, !self.finished else { return }
            var items: [(title: String, url: String)] = []
            if let json = result as? String,
               let data = json.data(using: .utf8),
               let parsed = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [[String: Any]] {
                for obj in parsed {
                    if let title = obj["title"] as? String,
                       let url = obj["url"] as? String,
                       !url.isEmpty {
                        items.append((title: title, url: url))
                    }
                }
            }
            if items.isEmpty && self.retries < 4 {
                self.retries += 1
                self.scheduleExtract(after: 2.2)
                return
            }
            self.finish(status: items.isEmpty ? "无结果/需验证" : "\(items.count) 条结果", items: items)
        }
    }

    private func finish(status: String, items: [(title: String, url: String)]) {
        guard !finished else { return }
        finished = true
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        webView.stopLoading()
        webView.navigationDelegate = nil
        onDone(SearchAggregator.SiteResult(site: site, status: status, items: items))
    }
}
