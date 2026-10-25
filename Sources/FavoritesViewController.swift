import UIKit

/// 收藏 Tab：视频收藏夹 / 论坛收藏夹 分段切换
final class FavoritesViewController: UITableViewController, ScrollToTopable {

    private enum Segment: Int {
        case videos = 0
        case forums = 1
    }

    private static let segmentKey = "fb_favorites_segment"

    private lazy var addFolderButton = makeHeaderIconButton(systemName: "plus",
                                                            action: #selector(addFolder))

    private let headerTitleLabel = UILabel()
    private let headerSubtitleLabel = UILabel()
    private let segmented = UISegmentedControl(items: ["视频收藏", "论坛收藏夹"])

    private var segment: Segment = .videos
    private var videoFolders: [VideoFavoriteFolder] = []
    private var folders: [FavoriteFolder] = []
    private var favoritesObserver: NSObjectProtocol?
    private var videoFavoritesObserver: NSObjectProtocol?

    deinit {
        if let observer = favoritesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = videoFavoritesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Theme.cardBorder
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 16)
        tableView.rowHeight = 68 * AppSettings.shared.fontScale
        tableView.sectionHeaderTopPadding = 8
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.register(SiteRowCell.self, forCellReuseIdentifier: SiteRowCell.reuseID)
        tableView.register(FavoritesEmptyCell.self,
                           forCellReuseIdentifier: FavoritesEmptyCell.reuseID)
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.title = "收藏"
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItems = nil
        navigationController?.navigationBar.prefersLargeTitles = false

        if let raw = UserDefaults.standard.object(forKey: Self.segmentKey) as? Int,
           let saved = Segment(rawValue: raw) {
            segment = saved
        } else {
            segment = VideoFavoriteStore.shared.folders.isEmpty ? .forums : .videos
        }

        setupHeader()
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)

        favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesChanged,
                                                                   object: nil,
                                                                   queue: .main) { [weak self] _ in
            self?.reloadData()
        }
        videoFavoritesObserver = NotificationCenter.default.addObserver(forName: .videoFavoritesChanged,
                                                                       object: nil,
                                                                       queue: .main) { [weak self] _ in
            self?.reloadData()
        }
        reloadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
        if let header = tableView.tableHeaderView, header.frame.width != tableView.bounds.width {
            header.frame.size.width = tableView.bounds.width
            tableView.tableHeaderView = header
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    func scrollToTop() {
        let top = -tableView.adjustedContentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: top), animated: true)
    }

    /// 从视频页星标进入时，默认展示视频收藏
    func showVideos() {
        segment = .videos
        UserDefaults.standard.set(Segment.videos.rawValue, forKey: Self.segmentKey)
        guard isViewLoaded else { return }
        segmented.selectedSegmentIndex = Segment.videos.rawValue
        updateChrome()
        tableView.reloadData()
    }

    // MARK: - 头部

    private func makeHeaderIconButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = Theme.textDim
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        return button
    }

    private func setupHeader() {
        let width = max(tableView.bounds.width, view.bounds.width)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 86))
        header.backgroundColor = .clear

        headerTitleLabel.text = "收藏"
        headerTitleLabel.font = Theme.rounded(20, .bold)
        headerTitleLabel.textColor = Theme.text
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerTitleLabel)

        headerSubtitleLabel.font = Theme.font(12, .regular)
        headerSubtitleLabel.textColor = Theme.textDim
        headerSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerSubtitleLabel)

        segmented.selectedSegmentIndex = segment.rawValue
        segmented.selectedSegmentTintColor = Theme.card
        segmented.backgroundColor = Theme.tonal
        segmented.setTitleTextAttributes([
            .foregroundColor: Theme.textDim,
            .font: Theme.font(13, .medium)
        ], for: .normal)
        segmented.setTitleTextAttributes([
            .foregroundColor: Theme.text,
            .font: Theme.font(13, .semibold)
        ], for: .selected)
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(segmented)

        let actions = UIStackView(arrangedSubviews: [addFolderButton])
        actions.axis = .horizontal
        actions.spacing = 2
        actions.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(actions)

        NSLayoutConstraint.activate([
            headerTitleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            headerTitleLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 6),
            headerTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: actions.leadingAnchor, constant: -8),

            headerSubtitleLabel.leadingAnchor.constraint(equalTo: headerTitleLabel.leadingAnchor),
            headerSubtitleLabel.topAnchor.constraint(equalTo: headerTitleLabel.bottomAnchor, constant: 0),
            headerSubtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: actions.leadingAnchor, constant: -8),

            segmented.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            segmented.topAnchor.constraint(equalTo: header.topAnchor, constant: 50),
            segmented.heightAnchor.constraint(equalToConstant: 30),

            actions.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -8),
            actions.topAnchor.constraint(equalTo: header.topAnchor, constant: 0)
        ])

        addFolderButton.accessibilityLabel = "新建收藏夹"
        tableView.tableHeaderView = header
        updateChrome()
    }

    private func updateChrome() {
        headerSubtitleLabel.text = "\(videoFolders.count) 个视频收藏夹 · \(folders.count) 个论坛收藏夹"
        segmented.selectedSegmentIndex = segment.rawValue
    }

    private func reloadData() {
        videoFolders = VideoFavoriteStore.shared.folders
        folders = FavoriteStore.shared.folders
        tableView.reloadData()
        updateChrome()
    }

    @objc private func segmentChanged() {
        segment = Segment(rawValue: segmented.selectedSegmentIndex) ?? .videos
        UserDefaults.standard.set(segment.rawValue, forKey: Self.segmentKey)
        Haptics.tap()
        updateChrome()
        tableView.reloadData()
    }

    // MARK: - 收藏夹动作

    @objc private func addFolder() {
        switch segment {
        case .videos:
            presentVideoFolderEditor(existing: nil)
        case .forums:
            presentFolderEditor(existing: nil)
        }
    }

    private func presentVideoFolderEditor(existing: VideoFavoriteFolder?) {
        let alert = UIAlertController(title: existing == nil ? "新建视频收藏夹" : "重命名视频收藏夹",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "收藏夹名称"
            field.text = existing?.name
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            if let existing = existing {
                VideoFavoriteStore.shared.renameFolder(id: existing.id, name: name)
            } else {
                VideoFavoriteStore.shared.addFolder(name: name)
            }
            self.reloadData()
        })
        present(alert, animated: true)
    }

    private func confirmDeleteVideoFolder(_ folder: VideoFavoriteFolder) {
        let count = VideoFavoriteStore.shared.count(in: folder.id)
        let message = count > 0
            ? "夹内的 \(count) 条视频收藏会一起删除，删除后不可恢复。"
            : "删除后不可恢复。"
        let alert = UIAlertController(title: "删除视频收藏夹「\(folder.name)」？",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            VideoFavoriteStore.shared.deleteFolder(id: folder.id)
            self?.reloadData()
        })
        present(alert, animated: true)
    }

    private func presentFolderEditor(existing: FavoriteFolder?) {
        let alert = UIAlertController(title: existing == nil ? "新建论坛收藏夹" : "重命名论坛收藏夹",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "收藏夹名称"
            field.text = existing?.name
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            if let existing = existing {
                FavoriteStore.shared.renameFolder(id: existing.id, name: name)
            } else {
                FavoriteStore.shared.addFolder(name: name)
            }
            self.reloadData()
        })
        present(alert, animated: true)
    }

    private func confirmDeleteFolder(_ folder: FavoriteFolder) {
        let count = FavoriteStore.shared.count(in: folder.id)
        let message = count > 0
            ? "夹内的 \(count) 条收藏会一起删除，删除后不可恢复。"
            : "删除后不可恢复。"
        let alert = UIAlertController(title: "删除论坛收藏夹「\(folder.name)」？",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            FavoriteStore.shared.deleteFolder(id: folder.id)
            self?.reloadData()
        })
        present(alert, animated: true)
    }

    private func openVideoFolder(_ folder: VideoFavoriteFolder) {
        let controller = VideoFavoritesListViewController(folderId: folder.id,
                                                          folderTitle: folder.name)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func openFolder(_ folder: FavoriteFolder) {
        let controller = FavoritesListViewController(folderId: folder.id, folderTitle: folder.name)
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - 表格

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segment {
        case .videos: return videoFolders.isEmpty ? 1 : videoFolders.count
        case .forums: return folders.isEmpty ? 1 : folders.count
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch segment {
        case .videos:
            return videoFolders.isEmpty ? 80 * AppSettings.shared.fontScale : 68 * AppSettings.shared.fontScale
        case .forums:
            return folders.isEmpty ? 80 * AppSettings.shared.fontScale : 68 * AppSettings.shared.fontScale
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch segment {
        case .videos:
            if videoFolders.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: FavoritesEmptyCell.reuseID,
                                                         for: indexPath) as! FavoritesEmptyCell
                cell.configure(text: "还没有视频收藏夹\n点右上角 + 新建收藏夹", icon: "play.rectangle")
                return cell
            }
            let folder = videoFolders[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: SiteRowCell.reuseID,
                                                     for: indexPath) as! SiteRowCell
            cell.configure(emoji: "📁",
                           title: folder.name,
                           subtitle: "\(VideoFavoriteStore.shared.count(in: folder.id)) 条视频")
            return cell

        case .forums:
            if folders.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: FavoritesEmptyCell.reuseID,
                                                         for: indexPath) as! FavoritesEmptyCell
                cell.configure(text: "还没有论坛收藏夹\n点右上角 + 新建收藏夹", icon: "folder")
                return cell
            }
            let folder = folders[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: SiteRowCell.reuseID,
                                                     for: indexPath) as! SiteRowCell
            cell.configure(emoji: "📁",
                           title: folder.name,
                           subtitle: "\(FavoriteStore.shared.count(in: folder.id)) 条收藏")
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch segment {
        case .videos:
            if videoFolders.isEmpty {
                presentVideoFolderEditor(existing: nil)
                return
            }
            guard indexPath.row < videoFolders.count else { return }
            openVideoFolder(videoFolders[indexPath.row])

        case .forums:
            if folders.isEmpty {
                presentFolderEditor(existing: nil)
                return
            }
            guard indexPath.row < folders.count else { return }
            openFolder(folders[indexPath.row])
        }
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        switch segment {
        case .videos:
            guard !videoFolders.isEmpty, indexPath.row < videoFolders.count else { return nil }
            let folder = videoFolders[indexPath.row]
            let rename = UIContextualAction(style: .normal, title: "重命名") { [weak self] _, _, completion in
                self?.presentVideoFolderEditor(existing: folder)
                completion(true)
            }
            rename.backgroundColor = Theme.accentSoft
            let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
                self?.confirmDeleteVideoFolder(folder)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [delete, rename])

        case .forums:
            guard !folders.isEmpty, indexPath.row < folders.count else { return nil }
            let folder = folders[indexPath.row]
            let rename = UIContextualAction(style: .normal, title: "重命名") { [weak self] _, _, completion in
                self?.presentFolderEditor(existing: folder)
                completion(true)
            }
            rename.backgroundColor = Theme.accentSoft
            let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
                self?.confirmDeleteFolder(folder)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [delete, rename])
        }
    }
}

/// 收藏页空状态行
final class FavoritesEmptyCell: UITableViewCell {

    static let reuseID = "FavoritesEmptyCell"

    private let iconView = UIImageView()
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = Theme.textFaint
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Theme.font(13, .regular)
        label.textColor = Theme.textDim
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 6),
            label.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String, icon: String = "folder") {
        label.text = text
        iconView.image = UIImage(systemName: icon)
    }
}
