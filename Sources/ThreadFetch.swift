import UIKit
import WebKit

struct ThreadItem {
    let title: String
    let url: String
    var thumbURL: String?

    init(title: String, url: String, thumbURL: String? = nil) {
        self.title = title
        self.url = url
        self.thumbURL = thumbURL
    }
}

struct SiteThreadResult {
    let site: Site
    let status: String
    let items: [ThreadItem]
}

/// 扁平信息流里的一条（帖子 + 来源站点）
struct FeedEntry {
    let site: Site
    let item: ThreadItem
}

/// 把各站结果交错合并（每个站轮流取一条），避免全挤在同一个站
func interleavedEntries(_ results: [SiteThreadResult]) -> [FeedEntry] {
    var perSite: [[FeedEntry]] = results.map { result in
        result.items.map { FeedEntry(site: result.site, item: $0) }
    }
    var entries: [FeedEntry] = []
    var index = 0
    while true {
        var added = false
        for list in perSite {
            if index < list.count {
                entries.append(list[index])
                added = true
            }
        }
        if !added { break }
        index += 1
    }
    return entries
}

/// 后台静默抓取一个页面里的帖子链接（搜索页 / 精华页通用）
final class ThreadFetchTask: NSObject, WKNavigationDelegate {

    private let requestURL: String
    private let needsAutoSearch: Bool
    private let webView: WKWebView
    private let completion: (String, [ThreadItem]) -> Void
    private var finished = false
    private var retries = 0
    private var timeoutTimer: Timer?

    var isFinished: Bool { return finished }

    init(requestURL: String,
         needsAutoSearch: Bool,
         completion: @escaping (String, [ThreadItem]) -> Void) {
        self.requestURL = requestURL
        self.needsAutoSearch = needsAutoSearch
        self.completion = completion

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()   // 复用登录态/Cookie
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        config.userContentController.addUserScript(
            WKUserScript(source: WebScripts.popupSuppressor,
                         injectionTime: .atDocumentStart,
                         forMainFrameOnly: false))
        if needsAutoSearch {
            config.userContentController.addUserScript(
                WKUserScript(source: WebScripts.autoSearch,
                             injectionTime: .atDocumentEnd,
                             forMainFrameOnly: true))
        }
        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 390, height: 800),
                                 configuration: config)

        super.init()
        self.webView.customUserAgent = UserAgents.mobileSafari
        self.webView.navigationDelegate = self
    }

    func start() {
        guard let url = URL(string: requestURL) else {
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
            var items: [ThreadItem] = []
            if let json = result as? String,
               let data = json.data(using: .utf8),
               let parsed = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [[String: Any]] {
                for obj in parsed {
                    if let title = obj["title"] as? String,
                       let url = obj["url"] as? String,
                       !url.isEmpty {
                        let thumb = obj["thumb"] as? String
                        items.append(ThreadItem(title: title,
                                                url: url,
                                                thumbURL: (thumb?.isEmpty == false) ? thumb : nil))
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

    private func finish(status: String, items: [ThreadItem]) {
        guard !finished else { return }
        finished = true
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        webView.stopLoading()
        webView.navigationDelegate = nil
        completion(status, items)
    }
}

/// 并发抓取多个站点（最多同时 2 个，单站 20 秒超时）
final class SiteFetchAggregator {

    private var pendingSites: [Site] = []
    private var activeTasks: [ThreadFetchTask] = []
    private var activeCount = 0
    private var urlProvider: ((Site) -> String?)?
    private var needsAutoSearch = false
    private var updateBlock: ((SiteThreadResult) -> Void)?
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
        urlProvider = nil
        updateBlock = nil
        finishBlock = nil
    }

    func start(sites: [Site],
               needsAutoSearch: Bool,
               urlForSite: @escaping (Site) -> String?,
               update: @escaping (SiteThreadResult) -> Void,
               finished: @escaping () -> Void) {
        cancel()
        isCancelled = false
        self.needsAutoSearch = needsAutoSearch
        self.urlProvider = urlForSite
        self.updateBlock = update
        self.finishBlock = finished
        pendingSites = sites.filter { urlForSite($0) != nil }
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
        guard let requestURL = urlProvider?(site) else {
            startNext()
            return
        }
        activeCount += 1
        let task = ThreadFetchTask(requestURL: requestURL,
                                   needsAutoSearch: needsAutoSearch) { [weak self] status, items in
            guard let self = self else { return }
            self.activeCount -= 1
            self.updateBlock?(SiteThreadResult(site: site, status: status, items: items))
            self.activeTasks.removeAll { $0.isFinished }
            self.startNext()
        }
        activeTasks.append(task)
        task.start()
    }
}
