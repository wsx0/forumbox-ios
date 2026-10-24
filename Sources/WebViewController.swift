import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    private let site: Site
    private var webView: WKWebView!
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private var observations: [NSKeyValueObservation] = []

    private lazy var backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
    private lazy var forwardButton = UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(goForward))
    private lazy var reloadButton = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(reload))
    private lazy var safariButton = UIBarButtonItem(image: UIImage(systemName: "safari"), style: .plain, target: self, action: #selector(openInSafari))

    init(site: Site) {
        self.site = site
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 11/255, green: 18/255, blue: 32/255, alpha: 1)
        title = site.name

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()   // 持久化 Cookie，登录态保留
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = Self.safariUserAgent
        view.addSubview(webView)
        self.webView = webView

        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1)
        progressView.trackTintColor = .clear
        progressView.isHidden = true
        view.addSubview(progressView)

        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.isTranslucent = false
        toolbar.barTintColor = UIColor(red: 11/255, green: 18/255, blue: 32/255, alpha: 1)
        toolbar.tintColor = UIColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 1)
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [backButton, flex, forwardButton, flex, reloadButton, flex, safariButton]
        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),

            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])

        observations.append(webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
            self?.updateButtons()
        })
        observations.append(webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
            self?.updateButtons()
        })
        observations.append(webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
            guard let self = self else { return }
            let p = Float(view.estimatedProgress)
            self.progressView.setProgress(p, animated: true)
            if p >= 1.0 {
                self.progressView.isHidden = true
            } else {
                self.progressView.isHidden = false
            }
        })

        updateButtons()
        load()
    }

    deinit {
        observations.forEach { $0.invalidate() }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func load() {
        guard let url = URL(string: site.url) else { return }
        webView.load(URLRequest(url: url))
    }

    private func updateButtons() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }

    @objc private func goBack() {
        if webView.canGoBack { webView.goBack() }
    }

    @objc private func goForward() {
        if webView.canGoForward { webView.goForward() }
    }

    @objc private func reload() {
        webView.reload()
    }

    @objc private func openInSafari() {
        guard let url = webView.url else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // target=_blank 的新窗口在当前 WebView 内打开
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }

    private static let safariUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1"
}
