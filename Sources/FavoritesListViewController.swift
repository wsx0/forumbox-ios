import UIKit

/// 收藏夹详情：某个收藏夹里的收藏列表
final class FavoritesListViewController: UITableViewController {

    private let folderId: UUID?
    private let folderTitleText: String
    private var items: [FavoriteItem] = []
    private let emptyHint = UILabel()

    init(folderId: UUID?, folderTitle: String) {
        self.folderId = folderId
        self.folderTitleText = folderTitle
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = folderTitleText
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Theme.cardBorder
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 16)
        tableView.rowHeight = 82 * AppSettings.shared.fontScale
        tableView.sectionHeaderTopPadding = 8
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.register(FavoriteRowCell.self, forCellReuseIdentifier: FavoriteRowCell.reuseID)
        navigationItem.backButtonDisplayMode = .minimal

        let background = Theme.makeBackgroundView(tableView.bounds)
        tableView.backgroundView = background
        emptyHint.text = "这个收藏夹还是空的"
        emptyHint.textAlignment = .center
        emptyHint.textColor = Theme.textFaint
        emptyHint.font = Theme.font(13, .regular)
        emptyHint.frame = background.bounds
        emptyHint.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        background.addSubview(emptyHint)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadItems()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
        if let background = tableView.backgroundView {
            emptyHint.frame = background.bounds
        }
    }

    private func loadItems() {
        items = FavoriteStore.shared.items(in: folderId)
        emptyHint.isHidden = !items.isEmpty
        tableView.reloadData()
    }

    private func presentMovePicker(item: FavoriteItem) {
        let targets = FavoriteStore.shared.folders.filter { $0.id != item.folderId }
        guard !targets.isEmpty else {
            presentNotice("没有其他收藏夹，请先在收藏页新建")
            return
        }
        let sheet = UIAlertController(title: "移动到收藏夹", message: nil, preferredStyle: .actionSheet)
        for folder in targets {
            sheet.addAction(UIAlertAction(title: folder.name, style: .default) { [weak self] _ in
                FavoriteStore.shared.move(id: item.id, to: folder.id)
                self?.loadItems()
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(sheet, animated: true)
    }

    // MARK: - 表格

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: FavoriteRowCell.reuseID,
                                                 for: indexPath) as! FavoriteRowCell
        cell.configure(emoji: item.siteEmoji,
                       title: item.title,
                       meta: "\(item.siteName) · \(Self.dateText(item.createdAt))")
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < items.count else { return }
        let item = items[indexPath.row]
        navigationController?.pushViewController(
            WebViewController(title: item.siteName, urlString: item.url),
            animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < items.count else { return nil }
        let item = items[indexPath.row]
        let move = UIContextualAction(style: .normal, title: "移动") { [weak self] _, _, completion in
            self?.presentMovePicker(item: item)
            completion(true)
        }
        move.backgroundColor = Theme.accentSoft
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            FavoriteStore.shared.remove(id: item.id)
            self?.loadItems()
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
