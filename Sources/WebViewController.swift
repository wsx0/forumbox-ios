import UIKit
import WebKit

final class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {

    private let site: Site
    private let searchQuery: String?
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

    private lazy var backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
    private lazy var forwardButton = UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(goForward))
    private lazy var reloadButton = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(reload))
    private lazy var safariButton = UIBarButtonItem(image: UIImage(systemName: "safari"), style: .plain, target: self, action: #selector(openInSafari))
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

    init(site: Site, searchQuery: String? = nil) {
        self.site = site
        self.searchQuery = searchQuery
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    convenience init(title: String, urlString: String) {
        self.init(site: Site(name: title, note: "", url: urlString, searchURL: nil))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.bgTop
        title = site.name
        navigationItem.rightBarButtonItems = [favoriteButton, moreButton]

        buildWebView()
        buildLayout()
        setupLoadingOverlay()
        observeWebView()
        updateButtons()

        setupContentRules { [weak self] in
            guard let self = self else { return }
            self.applyUserAgent()
            self.load()
        }
    }

    deinit {
        observations.forEach { $0.invalidate() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFavoriteButton()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    // MARK: - 构建

    private func buildWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()   // 持久化 Cookie，登录态保留
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let ucc = config.userContentController
        // 屏蔽 JS 弹窗（window.open）
        ucc.addUserScript(WKUserScript(source: WebScripts.popupSuppressor,
                                       injectionTime: .atDocumentStart,
                                       forMainFrameOnly: false))
        // 聚合搜索：跳到站内搜索页后，自动填写关键词并提交
        if searchQuery != nil {
            ucc.addUserScript(WKUserScript(source: WebScripts.autoSearch,
                                           injectionTime: .atDocumentEnd,
                                           forMainFrameOnly: true))
        }
        contentController = ucc

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isOpaque = false
        webView.backgroundColor = Theme.bgTop
        webView.scrollView.backgroundColor = Theme.bgTop
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

        let toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.isTranslucent = false
        toolbar.barTintColor = Theme.navBg
        toolbar.tintColor = Theme.textDim
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
    }

    private func observeWebView() {
        observations.append(webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
            self?.updateButtons()
        })
        observations.append(webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
            self?.updateButtons()
        })
        observations.append(webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
            guard let self = self else { return }
            let progress = Float(view.estimatedProgress)
            self.progressView.setProgress(progress, animated: true)
            self.progressView.isHidden = progress >= 1.0
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
        var target = site.url
        if searchQuery != nil, let searchURL = site.searchURL, !searchURL.isEmpty {
            target = searchURL
        }
        guard var url = URL(string: target) else { return }
        if let q = searchQuery, site.searchURL != nil,
           let encoded = q.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            url = URL(string: target + "#fbq=" + encoded) ?? url
        }
        isReaderMode = false
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

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isReaderMode = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateFavoriteButton()
        hideLoadingOverlay()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        hideLoadingOverlay()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        hideLoadingOverlay()
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
            return UIMenu(children: [openAction, copyAction, safariAction, shareAction])
        }
        completionHandler(configuration)
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

        let sheet = UIAlertController(title: "收藏到", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "未分类", style: .default) { [weak self] _ in
            self?.saveFavorite(folderId: nil)
        })
        for folder in FavoriteStore.shared.folders {
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

    private func saveFavorite(folderId: UUID?) {
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
