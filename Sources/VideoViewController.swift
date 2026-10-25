import UIKit
import SafariServices

/// 视频 Tab：固定头部 + 普通表格（站点 / 最近观看）
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
    private let pasteButton = UIButton(type: .system)
    private let openButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let sites = VideoSites.all
    private var entries: [VideoEntry] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        CrashLogger.log("video tab loaded")
        view.backgroundColor = Theme.bgTop
        setupHeader()
        setupTable()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        CrashLogger.log("video tab will appear")
        navigationController?.setNavigationBarHidden(true, animated: animated)
        reload()
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

        headerSubtitleLabel.text = "粘贴链接，网页视频在 App 内播放"
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

        pasteButton.setImage(UIImage(systemName: "doc.on.clipboard"), for: .normal)
        pasteButton.tintColor = Theme.textDim
        pasteButton.addTarget(self, action: #selector(pasteFromClipboard), for: .touchUpInside)
        pasteButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(pasteButton)

        openButton.setTitle("打开", for: .normal)
        openButton.setTitleColor(Theme.onAccent, for: .normal)
        openButton.titleLabel?.font = Theme.rounded(13, .semibold)
        openButton.backgroundColor = Theme.accent
        openButton.layer.cornerRadius = 17
        openButton.addTarget(self, action: #selector(openTypedURL), for: .touchUpInside)
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
            inputField.trailingAnchor.constraint(equalTo: pasteButton.leadingAnchor, constant: -4),

            pasteButton.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            pasteButton.widthAnchor.constraint(equalToConstant: 30),
            pasteButton.heightAnchor.constraint(equalToConstant: 34),
            pasteButton.trailingAnchor.constraint(equalTo: openButton.leadingAnchor, constant: -2),

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
        tableView.rowHeight = 72
        tableView.sectionHeaderTopPadding = 12
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SiteRowCell.self, forCellReuseIdentifier: SiteRowCell.reuseID)
        tableView.register(VideoRowCell.self, forCellReuseIdentifier: VideoRowCell.reuseID)
        tableView.register(VideoEmptyCell.self, forCellReuseIdentifier: VideoEmptyCell.reuseID)
        tableView.register(VideoClearCell.self, forCellReuseIdentifier: VideoClearCell.reuseID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        let background = Theme.makeBackgroundView(tableView.bounds)
        tableView.backgroundView = background

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: header.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - 数据

    private func reload() {
        entries = VideoHistoryStore.shared.entries
        tableView.reloadData()
    }

    @objc private func pasteFromClipboard() {
        guard let text = UIPasteboard.general.string?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty else {
            presentNotice("剪贴板里没有链接")
            return
        }
        inputField.text = text
        Haptics.tap()
    }

    @objc private func openTypedURL() {
        var text = (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            presentNotice("先粘贴一个视频链接")
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

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        openTypedURL()
        return true
    }

    private func openVideo(url: URL, title: String? = nil) {
        guard navigationController?.topViewController === self else { return }
        let host = url.host ?? "视频"
        let name = title ?? host
        VideoHistoryStore.shared.add(title: name, url: url.absoluteString)
        reload()
        Haptics.tap()

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
        controller.onTitleChange = { [weak self] pageTitle in
            VideoHistoryStore.shared.updateTitle(url: url.absoluteString, title: pageTitle)
            self?.reload()
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    @objc private func confirmClearHistory() {
        let alert = UIAlertController(title: "清空观看记录？",
                                      message: "只清空最近观看列表，不影响视频站点。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清空", style: .destructive) { [weak self] _ in
            VideoHistoryStore.shared.clear()
            self?.reload()
        })
        present(alert, animated: true)
    }

    // MARK: - 表格

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return sites.count }
        return entries.isEmpty ? 1 : entries.count + 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "站点" : "最近观看"
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = Theme.font(13, .semibold)
        header.textLabel?.textColor = Theme.textDim
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 68 * AppSettings.shared.fontScale
        }
        if entries.isEmpty {
            return 100
        }
        if indexPath.row == entries.count {
            return 48
        }
        return 72 * AppSettings.shared.fontScale
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let site = sites[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: SiteRowCell.reuseID,
                                                     for: indexPath) as! SiteRowCell
            cell.configure(emoji: site.emoji,
                           title: site.name,
                           subtitle: site.note,
                           preferEmoji: true)
            return cell
        }

        if entries.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: VideoEmptyCell.reuseID,
                                                     for: indexPath) as! VideoEmptyCell
            return cell
        }

        if indexPath.row == entries.count {
            return tableView.dequeueReusableCell(withIdentifier: VideoClearCell.reuseID,
                                                 for: indexPath)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: VideoRowCell.reuseID,
                                                 for: indexPath) as! VideoRowCell
        cell.configure(entry: entries[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            guard indexPath.row < sites.count,
                  let url = URL(string: sites[indexPath.row].url) else { return }
            openVideo(url: url, title: sites[indexPath.row].name)
            return
        }
        guard !entries.isEmpty else { return }
        if indexPath.row == entries.count {
            confirmClearHistory()
            return
        }
        guard indexPath.row < entries.count,
              let url = URL(string: entries[indexPath.row].url) else { return }
        openVideo(url: url, title: entries[indexPath.row].title)
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1,
              !entries.isEmpty,
              indexPath.row < entries.count else { return nil }
        let entry = entries[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            VideoHistoryStore.shared.remove(id: entry.id)
            self?.reload()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

/// 空观看记录
private final class VideoEmptyCell: UITableViewCell {

    static let reuseID = "VideoEmptyCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        textLabel?.text = "还没有观看记录\n点上面的站点或粘贴链接开始观看"
        textLabel?.numberOfLines = 0
        textLabel?.textAlignment = .center
        textLabel?.font = Theme.font(13, .regular)
        textLabel?.textColor = Theme.textDim
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 清空观看记录
private final class VideoClearCell: UITableViewCell {

    static let reuseID = "VideoClearCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = Theme.card
        contentView.backgroundColor = Theme.card
        selectionStyle = .default
        let selected = UIView()
        selected.backgroundColor = Theme.tonal
        selectedBackgroundView = selected
        textLabel?.text = "清空观看记录"
        textLabel?.textAlignment = .center
        textLabel?.font = Theme.rounded(13, .medium)
        textLabel?.textColor = Theme.accent
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 视频记录行：播放图标 + 标题 + 时间
final class VideoRowCell: UITableViewCell {

    static let reuseID = "VideoRowCell"

    private let iconBackground = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let chevronLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = Theme.card
        contentView.backgroundColor = Theme.card
        selectionStyle = .default
        let selected = UIView()
        selected.backgroundColor = Theme.tonal
        selectedBackgroundView = selected

        iconBackground.backgroundColor = Theme.tonal
        iconBackground.layer.cornerRadius = 12
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconBackground)

        iconView.image = UIImage(systemName: "play.rectangle.fill")
        iconView.tintColor = Theme.accent
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(iconView)

        titleLabel.font = Theme.rounded(15, .medium)
        titleLabel.textColor = Theme.text
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        metaLabel.font = Theme.font(13, .regular)
        metaLabel.textColor = Theme.textDim
        metaLabel.lineBreakMode = .byTruncatingTail
        metaLabel.translatesAutoresizingMaskIntoConstraints = false

        chevronLabel.text = "›"
        chevronLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        chevronLabel.textColor = Theme.textFaint
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(metaLabel)
        contentView.addSubview(chevronLabel)

        NSLayoutConstraint.activate([
            iconBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconBackground.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 44),
            iconBackground.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            chevronLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronLabel.widthAnchor.constraint(equalToConstant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),

            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            metaLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),
            metaLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -13)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(entry: VideoEntry) {
        titleLabel.text = entry.title
        let host = URL(string: entry.url)?.host ?? entry.url
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        metaLabel.text = "\(host) · \(formatter.string(from: entry.watchedAt))"
    }
}
