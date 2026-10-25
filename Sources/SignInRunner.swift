import UIKit
import WebKit

struct SignResult {
    let site: Site
    let status: String
}

/// 后台静默打开各站签到页，自动点击「签到」并回报结果
final class SignInRunner: NSObject, WKNavigationDelegate {

    private var webView: WKWebView?
    private var sites: [Site] = []
    private var results: [SignResult] = []
    private var index = 0
    private var currentSite: Site?
    private var completion: (([SignResult]) -> Void)?
    private var timeoutWork: DispatchWorkItem?
    private var isRunning = false
    private var currentToken = UUID()

    /// 进度回调（当前第几个 / 总数）
    var onProgress: ((Int, Int) -> Void)?

    private let scanJS = """
    (function () {
        try {
            var body = document.body ? (document.body.innerText || '') : '';
            if (/已签到|已经签到|今日已签到|签到成功|已打卡|签到完成/.test(body)) return 'done';
            if (/Just a moment|Checking your browser|安全验证|人机验证|请稍候/.test(body)) return 'challenge';
            if (/请先登录|需要登录|登录后|您还未登录|未登录/.test(body)) return 'login';
            var els = document.querySelectorAll('a,button,input,div,span');
            for (var i = 0; i < els.length; i++) {
                var el = els[i];
                var t = ((el.innerText || el.value || '') + '').replace(/\\s+/g, '');
                if (t && t.length <= 8 && /^(签到|打卡|立即签到|每日签到|签到打卡|点我签到|点击签到)$/.test(t)) {
                    el.click();
                    return 'clicked';
                }
            }
            return 'notfound';
        } catch (e) {
            return 'error';
        }
    })();
    """

    private let verifyJS = """
    (function () {
        var body = document.body ? (document.body.innerText || '') : '';
        if (/已签到|已经签到|今日已签到|签到成功|已打卡|签到完成/.test(body)) return 'ok';
        if (/请先登录|需要登录|登录后|未登录/.test(body)) return 'login';
        return 'unknown';
    })();
    """

    deinit {
        timeoutWork?.cancel()
        webView?.stopLoading()
        webView?.removeFromSuperview()
    }

    func run(sites: [Site], completion: @escaping ([SignResult]) -> Void) {
        guard !isRunning, !sites.isEmpty else { return }
        self.sites = sites
        self.results = []
        self.index = 0
        self.completion = completion
        self.isRunning = true
        setupWebView()
        loadNext()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let view = WKWebView(frame: CGRect(x: -10, y: -10, width: 1, height: 1), configuration: config)
        view.navigationDelegate = self
        view.customUserAgent = UserAgents.mobileSafari
        view.isUserInteractionEnabled = false
        view.alpha = 0.01
        if let window = keyWindow() {
            window.addSubview(view)
        }
        webView = view
    }

    private func keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    private func loadNext() {
        guard isRunning else { return }
        guard index < sites.count else {
            finish()
            return
        }
        let site = sites[index]
        currentSite = site
        guard let target = site.signURL, let url = URL(string: target) else {
            results.append(SignResult(site: site, status: "未配置签到地址"))
            currentSite = nil
            index += 1
            loadNext()
            return
        }
        currentToken = UUID()
        onProgress?(index + 1, sites.count)
        startTimeout()
        webView?.load(URLRequest(url: url))
    }

    private func startTimeout() {
        timeoutWork?.cancel()
        let token = currentToken
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.currentToken == token else { return }
            self.completeCurrent(status: "超时（可能需要验证）", token: token)
        }
        timeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 18, execute: work)
    }

    private func cancelTimeout() {
        timeoutWork?.cancel()
        timeoutWork = nil
    }

    private func completeCurrent(status: String, token: UUID) {
        guard token == currentToken, let site = currentSite else { return }
        cancelTimeout()
        results.append(SignResult(site: site, status: status))
        currentSite = nil
        currentToken = UUID()
        index += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.loadNext()
        }
    }

    private func finish() {
        isRunning = false
        cancelTimeout()
        webView?.stopLoading()
        webView?.removeFromSuperview()
        webView = nil
        currentSite = nil
        let output = results
        completion?(output)
        completion = nil
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        cancelTimeout()
        let token = currentToken
        let siteName = currentSite?.name
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.evaluateScan(token: token, siteName: siteName)
        }
    }

    private func evaluateScan(token: UUID, siteName: String?) {
        guard isRunning,
              let name = siteName,
              currentSite?.name == name,
              token == currentToken else { return }
        webView?.evaluateJavaScript(scanJS) { [weak self] result, _ in
            guard let self = self,
                  self.currentSite?.name == name,
                  token == self.currentToken else { return }
            let value = (result as? String) ?? "notfound"
            switch value {
            case "done":
                self.completeCurrent(status: "已签到", token: token)
            case "challenge":
                self.completeCurrent(status: "需要验证", token: token)
            case "login":
                self.completeCurrent(status: "需要登录", token: token)
            case "clicked":
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    self.verifySignResult(token: token, siteName: name)
                }
            default:
                self.completeCurrent(status: "未找到签到入口", token: token)
            }
        }
    }

    private func verifySignResult(token: UUID, siteName: String) {
        guard isRunning, currentSite?.name == siteName, token == currentToken else { return }
        webView?.evaluateJavaScript(verifyJS) { [weak self] result, _ in
            guard let self = self,
                  self.currentSite?.name == siteName,
                  token == self.currentToken else { return }
            let value = (result as? String) ?? "unknown"
            switch value {
            case "ok":
                self.completeCurrent(status: "签到成功", token: token)
            case "login":
                self.completeCurrent(status: "需要登录", token: token)
            default:
                self.completeCurrent(status: "已点击签到", token: token)
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleFailure(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleFailure(error)
    }

    private func handleFailure(_ error: Error) {
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled { return }
        completeCurrent(status: "打不开（网络/验证）", token: currentToken)
    }
}
