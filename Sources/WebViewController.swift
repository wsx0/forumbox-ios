import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    private let site: Site
    private let videoMode: Bool
    var onTitleChange: ((String) -> Void)?
    private var webView: WKWebView!
    private var contentController: WKUserContentController!
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private var observations: [NSKeyValueObservation] = []
    private var isReaderMode = false

    private let loadingOverlay = UIView()
    private let loadingEmoji = UILabel()
    private let loadingTitle = UILabel()
    private let loadingSpinner = UIActivityIndicatorView(style: .large)
    private var hasHiddenLoading = false
    private var favoritesObserver: NSObjectProtocol?

    private var toolbarBar: UIView!
    private var webBottomToToolbar: NSLayoutConstraint!
    private var webBottomToSafeArea: NSLayoutConstraint!
    private var toolbarHidden = false
    private var lastScrollOffset: CGFloat = 0
    private var ignoreScrollUntil = Date.distantPast
    private var isLoading = false
    private var hasFadedInContent = false
    private var isTransferring115 = false
    private var ed2kHandlerRegistered = false

    private let errorOverlay = UIView()
    private let errorDetailLabel = UILabel()

    private lazy var backButton = makeToolbarButton(icon: "chevron.left", action: #selector(goBack))
    private lazy var forwardButton = makeToolbarButton(icon: "chevron.right", action: #selector(goForward))
    private lazy var reloadButton = makeToolbarButton(icon: "arrow.clockwise", action: #selector(reloadOrStop))
    private lazy var homeButton = makeToolbarButton(icon: "house", action: #selector(goHome))
    private lazy var moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showMoreMenu))
    private lazy var favoriteButton = UIBarButtonItem(image: UIImage(systemName: "star"), style: .plain, target: self, action: #selector(toggleFavorite))

    private var adBlockEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "fb_adblock_enabled") == nil { return true }
            return UserDefaults.standard.bool(forKey: "fb_adblock_enabled")
        }
        set { UserDefaults.standard.set(newValue, forKey: "fb_adblock_enabled") }
    }

    private var desktopUA: Bool {
        get { return UserDefaults.standard.bool(forKey: "fb_desktop_ua") }
        set { UserDefaults.standard.set(newValue, forKey: "fb_desktop_ua") }
    }

    init(site: Site, videoMode: Bool = false) {
        self.site = site
        self.videoMode = videoMode
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    convenience init(title: String, urlString: String, videoMode: Bool = false) {
        self.init(site: Site(name: title, note: "", url: urlString), videoMode: videoMode)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        CrashLogger.log("webview load \(site.url) video=\(videoMode)")
        view.backgroundColor = Theme.bgTop
        title = site.name
        navigationItem.rightBarButtonItems = [favoriteButton, moreButton]

        buildWebView()
        buildLayout()
        setupLoadingOverlay()
        setupErrorOverlay()
        observeWebView()
        updateButtons()

        // 下拉刷新
        let refresh = UIRefreshControl()
        refresh.tintColor = Theme.accent
        refresh.addTarget(self, action: #selector(pulledToRefresh), for: .valueChanged)
        webView.scrollView.refreshControl = refresh

        // 收藏在其他页面被修改时，同步星标
        favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesChanged,
                                                                   object: nil,
                                                                   queue: .main) { [weak self] _ in
            self?.updateFavoriteButton()
        }

        setupContentRules { [weak self] in
            guard let self = self else { return }
            self.applyUserAgent()
            self.load()
        }
    }

    deinit {
        observations.forEach { $0.invalidate() }
        // 只移除确实注册过的 handler（未注册时移除在 WebKit 里有已知的竞态崩溃）
        if ed2kHandlerRegistered {
            contentController?.removeScriptMessageHandler(forName: "ed2k")
        }
        if let observer = favoritesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFavoriteButton()
        // 关闭系统整页 pop：右滑只用于网页内回退，不再误触退回列表
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return videoMode ? .allButUpsideDown : .portrait
    }

    // MARK: - 构建

    private func buildWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()   // 持久化 Cookie，登录态保留
        config.allowsInlineMediaPlayback = true
        if videoMode {
            // 视频兼容模式：明确关闭 PiP / AirPlay / 自动播放，避免 iOS 26 WebKit 播放崩溃
            config.mediaTypesRequiringUserActionForPlayback = .all
            config.allowsPictureInPictureMediaPlayback = false
            config.allowsAirPlayForMediaPlayback = false
        } else {
            config.mediaTypesRequiringUserActionForPlayback = []
            config.allowsPictureInPictureMediaPlayback = true
            config.allowsAirPlayForMediaPlayback = true
        }

        let ucc = config.userContentController
        // 屏蔽 JS 弹窗（window.open）
        ucc.addUserScript(WKUserScript(source: WebScripts.popupSuppressor,
                                       injectionTime: .atDocumentStart,
                                       forMainFrameOnly: false))
        // ED2K 链接识别 + 悬浮「转存 115」按钮（视频模式不需要）
        if !videoMode {
            ucc.add(WeakScriptHandler(delegate: self), name: "ed2k")
            ed2kHandlerRegistered = true
            ucc.addUserScript(WKUserScript(source: WebScripts.ed2kScanner,
                                           injectionTime: .atDocumentEnd,
                                           forMainFrameOnly: true))
        } else {
            // 让网页视频内联播放，并保留原生全屏按钮
            ucc.addUserScript(WKUserScript(source: WebScripts.videoEnhancer,
                                           injectionTime: .atDocumentEnd,
                                           forMainFrameOnly: true))
        }
        contentController = ucc

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isOpaque = false
        webView.backgroundColor = Theme.bgTop
        webView.scrollView.backgroundColor = Theme.bgTop
        webView.alpha = 0
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)
        self.webView = webView
    }

    private func buildLayout() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = Theme.accent
        progressView.trackTintColor = .clear
        progressView.isHidden = true
        view.addSubview(progressView)

        // 悬浮胶囊工具栏（替代原生 UIToolbar，和页面衔接更自然）
        let bar = UIView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = Theme.card
        bar.layer.cornerRadius = 24
        bar.layer.masksToBounds = false
        if Theme.palette.isLight {
            bar.layer.shadowColor = UIColor.black.cgColor
            bar.layer.shadowOpacity = 0.10
            bar.layer.shadowRadius = 14
            bar.layer.shadowOffset = CGSize(width: 0, height: 4)
        } else {
            bar.layer.borderWidth = 1
            bar.layer.borderColor = Theme.cardBorder.cgColor
        }
        view.addSubview(bar)
        toolbarBar = bar

        let stack = UIStackView(arrangedSubviews: [backButton, forwardButton, homeButton, reloadButton])
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(stack)

        webBottomToToolbar = webView.bottomAnchor.constraint(equalTo: bar.topAnchor, constant: -8)
        webBottomToSafeArea = webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        webBottomToToolbar.isActive = true

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            bar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bar.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            bar.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            bar.heightAnchor.constraint(equalToConstant: 48),

            stack.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -10),
            stack.topAnchor.constraint(equalTo: bar.topAnchor, constant: 2),
            stack.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -2),

            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    private func makeToolbarButton(icon: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = Theme.textDim
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        return button
    }

    private func observeWebView() {
        observations.append(webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
            self?.updateButtons()
        })
        observations.append(webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
            self?.updateButtons()
        })
        observations.append(webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
            self?.progressView.setProgress(Float(view.estimatedProgress), animated: true)
        })
        observations.append(webView.scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
            self?.handleScroll(scrollView.contentOffset.y)
        })
    }

    // MARK: - 加载过渡（让打开论坛的过程和 App 风格统一）

    private func setupLoadingOverlay() {
        loadingOverlay.backgroundColor = Theme.bgTop
        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingOverlay)
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        loadingEmoji.text = site.emoji
        loadingEmoji.font = .systemFont(ofSize: 42)
        loadingEmoji.textAlignment = .center
        loadingEmoji.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(loadingEmoji)

        loadingTitle.text = "正在打开 \(site.name)"
        loadingTitle.font = Theme.rounded(14, .medium)
        loadingTitle.textColor = Theme.textDim
        loadingTitle.textAlignment = .center
        loadingTitle.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(loadingTitle)

        loadingSpinner.color = Theme.accent
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        loadingOverlay.addSubview(loadingSpinner)
        loadingSpinner.startAnimating()

        NSLayoutConstraint.activate([
            loadingSpinner.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingSpinner.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor),
            loadingEmoji.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingEmoji.bottomAnchor.constraint(equalTo: loadingSpinner.topAnchor, constant: -18),
            loadingTitle.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingTitle.topAnchor.constraint(equalTo: loadingSpinner.bottomAnchor, constant: 12)
        ])
    }

    private func hideLoadingOverlay() {
        guard !hasHiddenLoading else { return }
        hasHiddenLoading = true
        loadingSpinner.stopAnimating()
        UIView.animate(withDuration: 0.25, animations: {
            self.loadingOverlay.alpha = 0
        }, completion: { _ in
            self.loadingOverlay.isHidden = true
        })
    }

    // MARK: - 错误页 / 加载状态 / 工具栏自动隐藏

    private func setupErrorOverlay() {
        errorOverlay.backgroundColor = Theme.bgTop
        errorOverlay.translatesAutoresizingMaskIntoConstraints = false
        errorOverlay.isHidden = true
        view.addSubview(errorOverlay)
        NSLayoutConstraint.activate([
            errorOverlay.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorOverlay.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            errorOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let emoji = UILabel()
        emoji.text = "📡"
        emoji.font = .systemFont(ofSize: 44)

        let title = UILabel()
        title.text = "网页打不开"
        title.font = Theme.rounded(17, .bold)
        title.textColor = Theme.text
        title.textAlignment = .center

        errorDetailLabel.font = .systemFont(ofSize: 12.5)
        errorDetailLabel.textColor = Theme.textFaint
        errorDetailLabel.numberOfLines = 3
        errorDetailLabel.textAlignment = .center

        let retry = UIButton(type: .system)
        retry.setTitle("重新加载", for: .normal)
        retry.setTitleColor(Theme.onAccent, for: .normal)
        retry.titleLabel?.font = Theme.rounded(14, .semibold)
        retry.backgroundColor = Theme.accent
        retry.layer.cornerRadius = 12
        retry.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        retry.addTarget(self, action: #selector(retryFromError), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [emoji, title, errorDetailLabel, retry])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(18, after: errorDetailLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        errorOverlay.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: errorOverlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: errorOverlay.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: errorOverlay.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: errorOverlay.trailingAnchor, constant: -32)
        ])
    }

    private func showError(_ message: String) {
        errorDetailLabel.text = message + "\n请检查网络 / 代理，或稍后重试"
        errorOverlay.isHidden = false
        view.bringSubviewToFront(errorOverlay)
        view.bringSubviewToFront(toolbarBar)
    }

    private func hideError() {
        errorOverlay.isHidden = true
    }

    @objc private func retryFromError() {
        hideError()
        Haptics.tap()
        if webView.url == nil {
            load()
        } else {
            webView.reload()
        }
    }

    private func setLoading(_ loading: Bool) {
        isLoading = loading
        progressView.isHidden = !loading
        if loading {
            progressView.setProgress(0, animated: false)
        }
        reloadButton.setImage(UIImage(systemName: loading ? "xmark" : "arrow.clockwise"), for: .normal)
    }

    @objc private func stopLoading() {
        Haptics.tap()
        webView.stopLoading()
        setLoading(false)
    }

    private func handleScroll(_ offset: CGFloat) {
        guard Date() > ignoreScrollUntil else { return }
        let delta = offset - lastScrollOffset
        lastScrollOffset = offset
        guard abs(delta) > 28 else { return }
        if offset < 80 {
            setToolbarHidden(false, animated: true)
        } else if delta > 0 {
            setToolbarHidden(true, animated: true)
        } else if delta < -8 {
            setToolbarHidden(false, animated: true)
        }
    }

    private func setToolbarHidden(_ hidden: Bool, animated: Bool) {
        guard toolbarHidden != hidden else { return }
        toolbarHidden = hidden
        ignoreScrollUntil = Date().addingTimeInterval(0.35)
        if !hidden {
            toolbarBar.isHidden = false
        }
        if hidden {
            webBottomToToolbar.isActive = false
            webBottomToSafeArea.isActive = true
        } else {
            webBottomToSafeArea.isActive = false
            webBottomToToolbar.isActive = true
        }

        let animations = {
            self.toolbarBar.transform = hidden
                ? CGAffineTransform(translationX: 0, y: self.toolbarBar.bounds.height + 40)
                : .identity
            self.view.layoutIfNeeded()
        }
        let completion: (Bool) -> Void = { _ in
            if hidden {
                self.toolbarBar.isHidden = true
                self.toolbarBar.transform = .identity
            }
        }
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut],
                           animations: animations, completion: completion)
        } else {
            animations()
            completion(true)
        }
    }

    @objc private func pulledToRefresh() {
        Haptics.tap()
        setLoading(true)
        webView.reload()
    }

    // MARK: - 边缘手势

    // 网页回退使用 WKWebView 自带的跟手手势（allowsBackForwardNavigationGestures）
    // 没有上一页时不再自定义 pop，避免误触直接退出；退出请点左上角返回。

    // MARK: - 广告拦截

    private func setupContentRules(completion: @escaping () -> Void) {
        guard adBlockEnabled,
              let url = Bundle.main.url(forResource: "AdBlockRules", withExtension: "json"),
              let json = try? String(contentsOf: url, encoding: .utf8) else {
            completion()
            return
        }
        WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "forumbox_adblock",
                                                                encodedContentRuleList: json) { [weak self] list, _ in
            DispatchQueue.main.async {
                if let list = list, let self = self {
                    self.contentController.add(list)
                }
                completion()
            }
        }
    }

    private func toggleAdBlock() {
        adBlockEnabled = !adBlockEnabled
        contentController.removeAllContentRuleLists()
        if adBlockEnabled {
            setupContentRules { [weak self] in
                self?.webView.reload()
            }
        } else {
            webView.reload()
        }
    }

    // MARK: - UA

    private func applyUserAgent() {
        webView.customUserAgent = desktopUA ? UserAgents.desktopChrome : UserAgents.mobileSafari
    }

    private func toggleDesktopUA() {
        desktopUA = !desktopUA
        applyUserAgent()
        webView.reload()
    }

    // MARK: - 阅读模式

    private func toggleReaderMode() {
        if isReaderMode {
            isReaderMode = false
            webView.reload()
            return
        }
        guard let url = Bundle.main.url(forResource: "Reader", withExtension: "js"),
              let js = try? String(contentsOf: url, encoding: .utf8) else {
            presentNotice("找不到阅读模式脚本")
            return
        }
        webView.evaluateJavaScript(js) { [weak self] result, _ in
            guard let self = self else { return }
            if let value = result as? String, value == "ok" {
                self.isReaderMode = true
            } else {
                self.isReaderMode = false
                self.presentNotice("这个页面没有可提取的正文（可能是列表页或脚本渲染页）")
            }
        }
    }

    // MARK: - 菜单

    @objc private func showMoreMenu() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let readerTitle = isReaderMode ? "退出阅读模式" : "阅读模式"
        sheet.addAction(UIAlertAction(title: readerTitle, style: .default) { [weak self] _ in
            self?.toggleReaderMode()
        })

        let uaTitle = desktopUA ? "切换为手机版" : "切换为桌面版"
        sheet.addAction(UIAlertAction(title: uaTitle, style: .default) { [weak self] _ in
            self?.toggleDesktopUA()
        })

        let adTitle = adBlockEnabled ? "广告拦截：已开启（点击关闭）" : "广告拦截：已关闭（点击开启）"
        sheet.addAction(UIAlertAction(title: adTitle, style: .default) { [weak self] _ in
            self?.toggleAdBlock()
        })

        sheet.addAction(UIAlertAction(title: "刷新页面", style: .default) { [weak self] _ in
            self?.webView.reload()
        })

        sheet.addAction(UIAlertAction(title: "用 Safari 打开", style: .default) { [weak self] _ in
            self?.openInSafari()
        })

        sheet.addAction(UIAlertAction(title: "复制当前链接", style: .default) { [weak self] _ in
            if let url = self?.webView.url { UIPasteboard.general.url = url }
        })

        sheet.addAction(UIAlertAction(title: "分享页面", style: .default) { [weak self] _ in
            self?.sharePage()
        })

        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = moreButton
        }
        present(sheet, animated: true)
    }

    private func presentNotice(_ text: String) {
        let alert = UIAlertController(title: "提示", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }

    // MARK: - 导航

    private func load() {
        guard let url = URL(string: site.url) else { return }
        isReaderMode = false
        webView.load(URLRequest(url: url))
    }

    private func updateButtons() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }

    @objc private func goBack() {
        Haptics.tap()
        if webView.canGoBack { webView.goBack() }
    }

    @objc private func goForward() {
        Haptics.tap()
        if webView.canGoForward { webView.goForward() }
    }

    @objc private func reload() {
        Haptics.tap()
        webView.reload()
    }

    @objc private func reloadOrStop() {
        if isLoading {
            stopLoading()
        } else {
            reload()
        }
    }

    @objc private func goHome() {
        Haptics.tap()
        guard let url = URL(string: site.url) else { return }
        isReaderMode = false
        webView.load(URLRequest(url: url))
    }

    @objc private func openInSafari() {
        Haptics.tap()
        guard let url = webView.url else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    private func sharePage() {
        guard let url = webView.url else { return }
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let pop = activity.popoverPresentationController {
            pop.barButtonItem = moreButton
        }
        present(activity, animated: true)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isReaderMode = false
        hideError()
        setLoading(true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        setLoading(false)
        webView.scrollView.refreshControl?.endRefreshing()
        updateFavoriteButton()
        hideLoadingOverlay()
        if videoMode,
           let pageTitle = webView.title?.trimmingCharacters(in: .whitespacesAndNewlines),
           !pageTitle.isEmpty {
            title = pageTitle
            onTitleChange?(pageTitle)
        }
        if !hasFadedInContent {
            hasFadedInContent = true
            UIView.animate(withDuration: 0.25) {
                self.webView.alpha = 1
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
        setLoading(false)
        webView.scrollView.refreshControl?.endRefreshing()
        hideLoadingOverlay()
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled {
            return
        }
        if !hasFadedInContent {
            hasFadedInContent = true
            webView.alpha = 1
        }
        showError(nsError.localizedDescription)
    }

    // 非 http(s) 链接（magnet / tg / mailto 等）交给系统处理
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let scheme = (url.scheme ?? "").lowercased()
        if scheme == "ed2k" {
            decisionHandler(.cancel)
            presentED2KActions(link: url.absoluteString)
            return
        }
        let inAppSchemes: Set<String> = ["http", "https", "file", "about", "data", "blob", "javascript"]
        if scheme.isEmpty || inAppSchemes.contains(scheme) {
            decisionHandler(.allow)
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIPasteboard.general.string = url.absoluteString
            presentNotice("已复制链接：\(url.absoluteString)")
        }
        decisionHandler(.cancel)
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

    // MARK: - 长按菜单增强（链接）

    func webView(_ webView: WKWebView,
                 contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
                 completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        guard let link = elementInfo.linkURL else {
            completionHandler(nil)   // 图片/文字保留系统默认菜单
            return
        }
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let openAction = UIAction(title: "在当前页打开",
                                      image: UIImage(systemName: "arrow.right.circle")) { _ in
                webView.load(URLRequest(url: link))
            }
            let copyAction = UIAction(title: "复制链接",
                                      image: UIImage(systemName: "doc.on.doc")) { _ in
                UIPasteboard.general.url = link
            }
            let safariAction = UIAction(title: "用 Safari 打开",
                                        image: UIImage(systemName: "safari")) { _ in
                UIApplication.shared.open(link, options: [:], completionHandler: nil)
            }
            let shareAction = UIAction(title: "分享链接",
                                       image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                guard let self = self else { return }
                let activity = UIActivityViewController(activityItems: [link], applicationActivities: nil)
                self.present(activity, animated: true)
            }
            var children: [UIMenuElement] = [openAction, copyAction, safariAction, shareAction]
            if link.scheme?.lowercased() == "ed2k" {
                let transfer = UIAction(title: "转存到 115 网盘",
                                        image: UIImage(systemName: "icloud.and.arrow.up")) { [weak self] _ in
                    self?.transferTo115(link.absoluteString)
                }
                children.insert(transfer, at: 0)
            }
            return UIMenu(children: children)
        }
        completionHandler(configuration)
    }

    // MARK: - ED2K → 115 网盘

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard message.name == "ed2k",
              let body = message.body as? [String: Any],
              let links = body["links"] as? [String],
              !links.isEmpty else { return }
        presentED2KList(links)
    }

    private func presentED2KList(_ links: [String]) {
        let sheet = UIAlertController(title: "发现 \(links.count) 个 ED2K 链接",
                                      message: "选择要转存到 115 云下载的链接",
                                      preferredStyle: .actionSheet)
        for link in links.prefix(20) {
            let short = link.count > 46 ? String(link.prefix(46)) + "…" : link
            sheet.addAction(UIAlertAction(title: short, style: .default) { [weak self] _ in
                self?.transferTo115(link)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = moreButton
        }
        present(sheet, animated: true)
    }

    private func presentED2KActions(link: String) {
        let sheet = UIAlertController(title: "ED2K 链接", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "转存到 115 网盘", style: .default) { [weak self] _ in
            self?.transferTo115(link)
        })
        sheet.addAction(UIAlertAction(title: "复制链接", style: .default) { _ in
            UIPasteboard.general.string = link
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = moreButton
        }
        present(sheet, animated: true)
    }

    private func transferTo115(_ link: String) {
        guard !isTransferring115 else { return }
        isTransferring115 = true
        UIPasteboard.general.string = link
        Haptics.tap()

        let busy = UIAlertController(title: "正在添加到 115…", message: nil, preferredStyle: .alert)
        var busyShown = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self, self.isTransferring115 else { return }
            busyShown = true
            self.present(busy, animated: true)
        }

        Cloud115.shared.addED2K(link) { [weak self] result in
            guard let self = self else { return }
            self.isTransferring115 = false
            let finish = {
                switch result {
                case .success:
                    Haptics.success()
                    self.presentNotice("已添加到 115 云下载\n可在 115 App 里查看进度")
                case .failure(.notLoggedIn):
                    self.prompt115Login(link: link)
                case .failure(.failed(let message)):
                    self.show115Failure(message, link: link)
                }
            }
            if busyShown {
                busy.dismiss(animated: true, completion: finish)
            } else {
                finish()
            }
        }
    }

    private func prompt115Login(link: String) {
        let alert = UIAlertController(title: "需要登录 115 网盘",
                                      message: "登录后会自动把 ED2K 加入 115 云下载",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "去登录", style: .default) { [weak self] _ in
            self?.navigationController?.pushViewController(
                WebViewController(title: "115 网盘", urlString: "https://115.com/"),
                animated: true)
        })
        alert.addAction(UIAlertAction(title: "仅复制链接", style: .default) { [weak self] _ in
            UIPasteboard.general.string = link
            self?.presentNotice("ED2K 链接已复制")
        })
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    private func show115Failure(_ message: String, link: String) {
        let alert = UIAlertController(title: "添加失败", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "复制链接", style: .default) { _ in
            UIPasteboard.general.string = link
        })
        alert.addAction(UIAlertAction(title: "好", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - 收藏

    @objc private func toggleFavorite() {
        let url = currentPageURL
        if let existing = FavoriteStore.shared.item(for: url) {
            let alert = UIAlertController(title: "取消收藏？", message: existing.title, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "取消收藏", style: .destructive) { [weak self] _ in
                FavoriteStore.shared.remove(id: existing.id)
                self?.updateFavoriteButton()
            })
            present(alert, animated: true)
            return
        }

        let folders = FavoriteStore.shared.folders
        guard !folders.isEmpty else {
            let alert = UIAlertController(title: "还没有收藏夹",
                                          message: "收藏只保存在收藏夹里，先新建一个收藏夹吧",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "新建收藏夹", style: .default) { [weak self] _ in
                self?.promptNewFolderAndSave()
            })
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(alert, animated: true)
            return
        }

        let sheet = UIAlertController(title: "收藏到收藏夹", message: nil, preferredStyle: .actionSheet)
        for folder in folders {
            sheet.addAction(UIAlertAction(title: folder.name, style: .default) { [weak self] _ in
                self?.saveFavorite(folderId: folder.id)
            })
        }
        sheet.addAction(UIAlertAction(title: "新建收藏夹…", style: .default) { [weak self] _ in
            self?.promptNewFolderAndSave()
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = favoriteButton
        }
        present(sheet, animated: true)
    }

    private var currentPageURL: String {
        let url = webView?.url?.absoluteString ?? ""
        return url.isEmpty ? site.url : url
    }

    private func saveFavorite(folderId: UUID) {
        var title = (webView?.title ?? site.name).trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty { title = site.name }
        FavoriteStore.shared.add(title: title,
                                 url: currentPageURL,
                                 siteName: site.name,
                                 siteEmoji: site.emoji,
                                 folderId: folderId)
        Haptics.success()
        updateFavoriteButton()
    }

    private func promptNewFolderAndSave() {
        let alert = UIAlertController(title: "新建收藏夹", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "收藏夹名称"
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "创建并收藏", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            let folder = FavoriteStore.shared.addFolder(name: name)
            self.saveFavorite(folderId: folder.id)
        })
        present(alert, animated: true)
    }

    private func updateFavoriteButton() {
        guard isViewLoaded, webView != nil else { return }
        let favorited = FavoriteStore.shared.isFavorited(url: currentPageURL)
        favoriteButton.image = UIImage(systemName: favorited ? "star.fill" : "star")
        favoriteButton.tintColor = favorited ? Theme.accent : nil
    }

    // MARK: - 常量
}

/// 弱引用代理，避免 WKUserContentController 强引用 WebViewController 造成循环
final class WeakScriptHandler: NSObject, WKScriptMessageHandler {

    private weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
