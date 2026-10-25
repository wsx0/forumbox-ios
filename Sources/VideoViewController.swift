import UIKit

/// 视频 Tab：粘贴视频链接，在 App 内用 WKWebView 播放网页视频
final class VideoViewController: UITableViewController, UITextFieldDelegate {

    private let headerTitleLabel = UILabel()
    private let headerSubtitleLabel = UILabel()
    private let inputContainer = UIView()
    private let inputField = UITextField()
    private let pasteButton = UIButton(type: .system)
    private let openButton = UIButton(type: .system)
    private let emptyLabel = UILabel()
    private lazy var clearButton = UIButton(type: .system)

    private let sites = VideoSites.all
    private var entries: [VideoEntry] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Theme.cardBorder
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 16)
        tableView.rowHeight = 72
        tableView.sectionHeaderTopPadding = 12
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.register(VideoRowCell.self, forCellReuseIdentifier: VideoRowCell.reuseID)
        navigationItem.title = "视频"
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItems = nil
        setupHeader()
        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        reload()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let header = tableView.tableHeaderView, header.frame.width != tableView.bounds.width {
            header.frame.size.width = tableView.bounds.width
            tableView.tableHeaderView = header
        }
        tableView.tableFooterView?.frame.size.width = tableView.bounds.width
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }


    // MARK: - 头部

    private func setupHeader() {
        let width = max(tableView.bounds.width, view.bounds.width)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 108))
        header.backgroundColor = .clear

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

        var config = UIButton.Configuration.filled()
        config.title = "打开"
        config.baseBackgroundColor = Theme.accent
        config.baseForegroundColor = Theme.onAccent
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.rounded(13, .semibold)
            return out
        }
        openButton.configuration = config
        openButton.addTarget(self, action: #selector(openTypedURL), for: .touchUpInside)
        openButton.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.addSubview(openButton)

        NSLayoutConstraint.activate([
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

        tableView.tableHeaderView = header
    }

    // MARK: - 数据

    private func reload() {
        entries = VideoHistoryStore.shared.entries
        tableView.reloadData()
        updateFooter()
    }

    private func updateFooter() {
        if entries.isEmpty {
            let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 110))
            footer.backgroundColor = .clear
            emptyLabel.text = "还没有观看记录\n点上面的站点或粘贴链接开始观看"
            emptyLabel.numberOfLines = 0
            emptyLabel.textAlignment = .center
            emptyLabel.font = Theme.font(13, .regular)
            emptyLabel.textColor = Theme.textDim
            emptyLabel.frame = footer.bounds
            emptyLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            footer.addSubview(emptyLabel)
            tableView.tableFooterView = footer
        } else {
            let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 56))
            footer.backgroundColor = .clear
            var config = UIButton.Configuration.plain()
            config.title = "清空观看记录"
            config.baseForegroundColor = Theme.accent
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var out = incoming
                out.font = Theme.rounded(13, .medium)
                return out
            }
            clearButton.configuration = config
            clearButton.removeTarget(nil, action: nil, for: .allEvents)
            clearButton.addTarget(self, action: #selector(confirmClearHistory), for: .touchUpInside)
            clearButton.frame = footer.bounds
            clearButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            footer.addSubview(clearButton)
            tableView.tableFooterView = footer
        }
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

    // MARK: - 打开视频

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
        Haptics.tap()
        let host = url.host ?? "视频"
        let name = title ?? host
        VideoHistoryStore.shared.add(title: name, url: url.absoluteString)
        reload()

        let controller = WebViewController(title: name, urlString: url.absoluteString, videoMode: true)
        controller.onTitleChange = { [weak self] pageTitle in
            VideoHistoryStore.shared.updateTitle(url: url.absoluteString, title: pageTitle)
            self?.reload()
        }
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - 表格

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? sites.count : entries.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "站点" : "最近观看"
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = Theme.font(13, .semibold)
        header.textLabel?.textColor = Theme.textDim
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath.section == 0 ? 68 : 72) * AppSettings.shared.fontScale
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: VideoRowCell.reuseID,
                                                 for: indexPath) as! VideoRowCell
        cell.configure(entry: entries[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            guard indexPath.row < sites.count,
                  let url = URL(string: sites[indexPath.row].url) else { return }
            openVideo(url: url, title: sites[indexPath.row].name)
            return
        }
        guard indexPath.row < entries.count,
              let url = URL(string: entries[indexPath.row].url) else { return }
        openVideo(url: url, title: entries[indexPath.row].title)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1, indexPath.row < entries.count else { return nil }
        let entry = entries[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            VideoHistoryStore.shared.remove(id: entry.id)
            self?.reload()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
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
