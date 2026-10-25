import UIKit

/// 收藏 Tab：只有收藏夹（收藏只保存在收藏夹里，不再显示最近收藏 / 未分类）
final class FavoritesViewController: UITableViewController {

    private lazy var addFolderButton = makeHeaderIconButton(systemName: "plus",
                                                            action: #selector(addFolder))

    private lazy var settingsButton = makeHeaderIconButton(systemName: "gearshape",
                                                           action: #selector(openSettings))

    private let headerTitleLabel = UILabel()
    private let headerSubtitleLabel = UILabel()
    private let emptyHint = UILabel()
    private var favoritesObserver: NSObjectProtocol?

    deinit {
        if let observer = favoritesObserver {
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
        tableView.sectionHeaderTopPadding = 12
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.register(SiteRowCell.self, forCellReuseIdentifier: SiteRowCell.reuseID)
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.title = "收藏"
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItems = nil
        navigationController?.navigationBar.prefersLargeTitles = false
        setupHeader()

        let background = Theme.makeBackgroundView(tableView.bounds)
        tableView.backgroundView = background
        emptyHint.text = "还没有收藏夹\n\n点右上角 + 新建收藏夹，收藏的帖子会保存在里面"
        emptyHint.numberOfLines = 0
        emptyHint.textAlignment = .center
        emptyHint.textColor = Theme.textDim
        emptyHint.font = Theme.font(13, .regular)
        emptyHint.frame = background.bounds
        emptyHint.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        background.addSubview(emptyHint)

        favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesChanged,
                                                                   object: nil,
                                                                   queue: .main) { [weak self] _ in
            self?.tableView.reloadData()
            self?.updateEmptyHint()
            self?.updateNavTitle()
        }
        updateNavTitle()
        updateEmptyHint()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tableView.reloadData()
        updateEmptyHint()
        updateNavTitle()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
        if let background = tableView.backgroundView {
            emptyHint.frame = background.bounds
        }
        if let header = tableView.tableHeaderView, header.frame.width != tableView.bounds.width {
            header.frame.size.width = tableView.bounds.width
            tableView.tableHeaderView = header
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

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
        let header = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 56))
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

        let actions = UIStackView(arrangedSubviews: [addFolderButton, settingsButton])
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

            actions.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -8),
            actions.centerYAnchor.constraint(equalTo: header.centerYAnchor)
        ])

        tableView.tableHeaderView = header
        updateNavTitle()
    }

    private func updateEmptyHint() {
        emptyHint.isHidden = !FavoriteStore.shared.folders.isEmpty
    }

    private func updateNavTitle() {
        let folders = FavoriteStore.shared.folders.count
        let items = FavoriteStore.shared.items.count
        headerSubtitleLabel.text = "\(folders) 个收藏夹 · \(items) 条收藏"
    }

    // MARK: - 动作

    @objc private func openSettings() {
        Haptics.tap()
        navigationController?.pushViewController(SettingsViewController(style: .insetGrouped), animated: true)
    }

    @objc private func addFolder() {
        presentFolderEditor(existing: nil)
    }

    private func presentFolderEditor(existing: FavoriteFolder?) {
        let alert = UIAlertController(title: existing == nil ? "新建收藏夹" : "重命名收藏夹",
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
            self.tableView.reloadData()
            self.updateNavTitle()
            self.updateEmptyHint()
        })
        present(alert, animated: true)
    }

    private func confirmDeleteFolder(_ folder: FavoriteFolder) {
        let count = FavoriteStore.shared.count(in: folder.id)
        let message = count > 0
            ? "夹内的 \(count) 条收藏会一起删除，删除后不可恢复。"
            : "删除后不可恢复。"
        let alert = UIAlertController(title: "删除收藏夹「\(folder.name)」？",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            FavoriteStore.shared.deleteFolder(id: folder.id)
            self?.tableView.reloadData()
            self?.updateNavTitle()
            self?.updateEmptyHint()
        })
        present(alert, animated: true)
    }

    private func openFolder(_ folder: FavoriteFolder) {
        let controller = FavoritesListViewController(folderId: folder.id, folderTitle: folder.name)
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - 数据

    private var folderRows: [FavoriteFolder] {
        return FavoriteStore.shared.folders
    }

    // MARK: - 表格

    override func numberOfSections(in tableView: UITableView) -> Int {
        return folderRows.isEmpty ? 0 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return folderRows.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "收藏夹"
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = Theme.font(13, .semibold)
        header.textLabel?.textColor = Theme.textDim
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68 * AppSettings.shared.fontScale
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let folder = folderRows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SiteRowCell.reuseID,
                                                 for: indexPath) as! SiteRowCell
        cell.configure(emoji: "📁",
                       title: folder.name,
                       subtitle: "\(FavoriteStore.shared.count(in: folder.id)) 条收藏")
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < folderRows.count else { return }
        openFolder(folderRows[indexPath.row])
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < folderRows.count else { return nil }
        let folder = folderRows[indexPath.row]
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
