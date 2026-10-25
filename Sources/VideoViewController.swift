import UIKit
import SafariServices

/// 视频 Tab：固定头部 + 站点列表（无最近观看、无粘贴按钮）
final class VideoViewController: UIViewController,
                                UITableViewDataSource,
                                UITableViewDelegate,
                                UITextFieldDelegate,
                                ScrollToTopable {

    private let header = UIView()
    private let headerTitleLabel = UILabel()
    private let headerSubtitleLabel = UILabel()
    private let inputContainer = UIView()
    private let inputField = UITextField()
    private let openButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let sites = VideoSites.all

    override func viewDidLoad() {
        super.viewDidLoad()
        CrashLogger.log("video tab loaded")
        view.backgroundColor = Theme.bgTop
        setupHeader()
        setupTable()
        tableView.reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        CrashLogger.log("video tab will appear")
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    func scrollToTop() {
        let top = -tableView.adjustedContentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: top), animated: true)
    }

    // MARK: - 头部

    private func setupHeader() {
        header.backgroundColor = Theme.bgTop
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        headerTitleLabel.text = "视频"
        headerTitleLabel.font = Theme.rounded(20, .bold)
        headerTitleLabel.textColor = Theme.text
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerTitleLabel)

        headerSubtitleLabel.text = "输入链接或点下方站点观看"
        headerSubtitleLabel.font = Theme.font(12, .regular)
        headerSubtitleLabel.textColor = Theme.textDim
        headerSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerSubtitleLabel)

        inputContainer.backgroundColor = Theme.card
        inputContainer.layer.cornerRadius = 12
        inputContainer.layer.borderWidth = 1
        inputContainer.layer.borderColor = Theme.cardBorder.cgColor
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(inputContainer)

        inputField.placeholder = "输入视频链接或网站"
        inputField.font = Theme.font(14, .regular)
        inputField.textColor = Theme.text
        inputField.tintColor = Theme.accent
        inputField.keyboardType = .URL
        inputField.returnKeyType = .go
        inputField.autocapitalizationType = .none
        inputField.autocorrectionType = .no
        inputField.clearButtonMode = .whileEditing
        inputField.delegate = self
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(inputField)

        openButton.setTitle("打开", for: .normal)
        openButton.setTitleColor(Theme.onAccent, for: .normal)
        openButton.titleLabel?.font = Theme.rounded(13, .semibold)
        openButton.backgroundColor = Theme.accent
        openButton.layer.cornerRadius = 17
        openButton.addTarget(self, action: #selector(openTypedURL), for: .touchUpInside)
        openButton.addTarget(self, action: #selector(openButtonDown), for: .touchDown)
        openButton.addTarget(self, action: #selector(openButtonUp),
                             for: [.touchUpInside, .touchUpOutside, .touchCancel])
        openButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(openButton)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 108),

            headerTitleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            headerTitleLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 6),
            headerTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -16),

            headerSubtitleLabel.leadingAnchor.constraint(equalTo: headerTitleLabel.leadingAnchor),
            headerSubtitleLabel.topAnchor.constraint(equalTo: headerTitleLabel.bottomAnchor, constant: 0),
            headerSubtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -16),

            inputContainer.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            inputContainer.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            inputContainer.topAnchor.constraint(equalTo: header.topAnchor, constant: 56),
            inputContainer.heightAnchor.constraint(equalToConstant: 44),

            inputField.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            inputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            inputField.trailingAnchor.constraint(equalTo: openButton.leadingAnchor, constant: -8),

            openButton.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -5),
            openButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            openButton.heightAnchor.constraint(equalToConstant: 34),
            openButton.widthAnchor.constraint(equalToConstant: 64)
        ])
    }

    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Theme.cardBorder
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 16)
        tableView.rowHeight = 68
        tableView.sectionHeaderTopPadding = 12
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SiteRowCell.self, forCellReuseIdentifier: SiteRowCell.reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: header.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - 打开链接

    @objc private func openTypedURL() {
        var text = (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            presentNotice("先输入一个视频链接")
            return
        }
        let lower = text.lowercased()
        if !lower.hasPrefix("http://") && !lower.hasPrefix("https://") {
            text = "https://" + text
        }
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            presentNotice("链接格式不正确，需要 http/https 地址")
            return
        }
        inputField.resignFirstResponder()
        inputField.text = ""
        openVideo(url: url)
    }

    @objc private func openButtonDown() {
        openButton.alpha = 0.78
    }

    @objc private func openButtonUp() {
        UIView.animate(withDuration: 0.15) {
            self.openButton.alpha = 1
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        openTypedURL()
        return true
    }

    private func openVideo(url: URL, title: String? = nil) {
        guard navigationController?.topViewController === self else { return }
        Haptics.tap()
        let host = url.host ?? "视频"
        let name = title ?? host

        if AppSettings.shared.videoUseSystemPlayer {
            CrashLogger.log("open video system \(url.absoluteString)")
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = Theme.accent
            safari.modalPresentationStyle = .fullScreen
            CrashLogger.log("presenting safari \(url.absoluteString)")
            present(safari, animated: true) {
                CrashLogger.log("safari presented \(url.absoluteString)")
            }
            return
        }

        CrashLogger.log("open video builtin \(url.absoluteString)")
        let controller = WebViewController(title: name, urlString: url.absoluteString, videoMode: true)
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - 表格

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sites.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "站点"
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = Theme.font(13, .semibold)
        header.textLabel?.textColor = Theme.textDim
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68 * AppSettings.shared.fontScale
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let site = sites[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SiteRowCell.reuseID,
                                                 for: indexPath) as! SiteRowCell
        cell.configure(emoji: site.emoji,
                       title: site.name,
                       subtitle: site.note,
                       preferEmoji: true)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < sites.count,
              let url = URL(string: sites[indexPath.row].url) else { return }
        openVideo(url: url, title: sites[indexPath.row].name)
    }
}
