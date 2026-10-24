import UIKit

/// 收藏 Tab：收藏夹列表 + 最近收藏
final class FavoritesViewController: UITableViewController {

    private lazy var themeButton = UIBarButtonItem(image: UIImage(systemName: "paintpalette"),
                                                   style: .plain,
                                                   target: self,
                                                   action: #selector(showThemePicker))

    private lazy var addFolderButton = UIBarButtonItem(barButtonSystemItem: .add,
                                                       target: self,
                                                       action: #selector(addFolder))

    private let emptyHint = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "收藏"
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 82
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 24, right: 0)
        tableView.register(CardCell.self, forCellReuseIdentifier: "CardCell")
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.leftBarButtonItem = themeButton
        navigationItem.rightBarButtonItem = addFolderButton
        navigationController?.navigationBar.prefersLargeTitles = false

        let background = Theme.makeBackgroundView(tableView.bounds)
        tableView.backgroundView = background
        emptyHint.text = "还没有收藏\n\n在任意帖子页面点右上角 ☆ 即可收藏"
        emptyHint.numberOfLines = 0
        emptyHint.textAlignment = .center
        emptyHint.textColor = Theme.textFaint
        emptyHint.font = Theme.rounded(14, .medium)
        emptyHint.frame = background.bounds
        emptyHint.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        background.addSubview(emptyHint)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateEmptyHint()
        updateBadge()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
        if let background = tableView.backgroundView {
            emptyHint.frame = background.bounds
        }
    }

    private func updateEmptyHint() {
        emptyHint.isHidden = !FavoriteStore.shared.items.isEmpty
    }

    private func updateBadge() {
        let count = FavoriteStore.shared.items.count
        navigationController?.tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
    }

    // MARK: - 动作

    @objc private func showThemePicker() {
        ThemePicker.present(from: self, sourceItem: themeButton)
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
        })
        present(alert, animated: true)
    }

    private func confirmDeleteFolder(_ folder: FavoriteFolder) {
        let alert = UIAlertController(title: "删除收藏夹「\(folder.name)」？",
                                      message: "夹内的收藏会移动到「未分类」。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            FavoriteStore.shared.deleteFolder(id: folder.id)
            self?.tableView.reloadData()
        })
        present(alert, animated: true)
    }

    private func openFolder(_ folderId: UUID?, title: String) {
        let controller = FavoritesListViewController(folderId: folderId, folderTitle: title)
        navigationController?.pushViewController(controller, animated: true)
    }

    private func presentMovePicker(item: FavoriteItem) {
        let sheet = UIAlertController(title: "移动到收藏夹", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "未分类", style: .default) { [weak self] _ in
            FavoriteStore.shared.move(id: item.id, to: nil)
            self?.tableView.reloadData()
        })
        for folder in FavoriteStore.shared.folders {
            sheet.addAction(UIAlertAction(title: folder.name, style: .default) { [weak self] _ in
                FavoriteStore.shared.move(id: item.id, to: folder.id)
                self?.tableView.reloadData()
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = addFolderButton
        }
        present(sheet, animated: true)
    }

    // MARK: - 数据

    private struct FolderRow {
        let id: UUID?
        let name: String
        let count: Int
    }

    private var folderRows: [FolderRow] {
        var rows: [FolderRow] = [FolderRow(id: nil, name: "未分类", count: FavoriteStore.shared.count(in: nil))]
        for folder in FavoriteStore.shared.folders {
            rows.append(FolderRow(id: folder.id,
                                  name: folder.name,
                                  count: FavoriteStore.shared.count(in: folder.id)))
        }
        return rows
    }

    private var recentItems: [FavoriteItem] {
        return FavoriteStore.shared.allItemsSorted()
    }

    // MARK: - 表格

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return folderRows.count
        }
        return recentItems.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        let label = UILabel()
        label.font = Theme.rounded(12, .semibold)
        label.textColor = Theme.textFaint
        label.translatesAutoresizingMaskIntoConstraints = false
        if section == 0 {
            label.text = "📁 收藏夹"
        } else {
            label.text = "🕘 最近收藏（\(recentItems.count)）"
        }
        header.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 24),
            label.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -4),
            label.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -16)
        ])
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 34
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let row = folderRows[indexPath.row]
            return tableView.dequeueCard(for: indexPath, model: CardCell.Model(
                emoji: row.id == nil ? "📥" : "📁",
                title: row.name,
                subtitle: "\(row.count) 条收藏",
                detail: nil,
                showsChevron: true))
        }
        let item = recentItems[indexPath.row]
        return tableView.dequeueCard(for: indexPath, model: CardCell.Model(
            emoji: item.siteEmoji,
            title: item.title,
            subtitle: "\(item.siteName) · \(FavoriteStore.shared.folderName(for: item.folderId))",
            detail: Self.dateText(item.createdAt),
            showsChevron: true))
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let row = folderRows[indexPath.row]
            openFolder(row.id, title: row.name)
            return
        }
        guard indexPath.row < recentItems.count else { return }
        let item = recentItems[indexPath.row]
        navigationController?.pushViewController(
            WebViewController(title: item.siteName, urlString: item.url),
            animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 0 {
            let row = folderRows[indexPath.row]
            guard let folderId = row.id,
                  let folder = FavoriteStore.shared.folders.first(where: { $0.id == folderId }) else { return nil }
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
        guard indexPath.row < recentItems.count else { return nil }
        let item = recentItems[indexPath.row]
        let move = UIContextualAction(style: .normal, title: "移动") { [weak self] _, _, completion in
            self?.presentMovePicker(item: item)
            completion(true)
        }
        move.backgroundColor = Theme.accentSoft
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            FavoriteStore.shared.remove(id: item.id)
            self?.tableView.reloadData()
            self?.updateEmptyHint()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete, move])
    }

    private static func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
