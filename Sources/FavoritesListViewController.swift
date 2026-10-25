import UIKit

/// 收藏夹详情：每页 10 条，底部页码分页
final class FavoritesListViewController: UITableViewController, UISearchResultsUpdating {

    private let folderId: UUID?
    private let folderTitleText: String
    private var items: [FavoriteItem] = []
    private var filteredItems: [FavoriteItem] = []
    private let emptyHint = UILabel()
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchText = ""

    private let pageSize = 10
    private var currentPage = 1

    private let paginationBar = UIView()
    private let pagesScroll = UIScrollView()
    private let pagesStack = UIStackView()
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)

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

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "搜索标题 / 站点"
        searchController.searchBar.tintColor = Theme.accent
        searchController.searchBar.searchTextField.backgroundColor = Theme.card
        searchController.searchBar.searchTextField.textColor = Theme.text
        searchController.searchBar.searchTextField.font = Theme.font(14, .regular)
        searchController.searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "搜索标题 / 站点",
            attributes: [
                .foregroundColor: Theme.textFaint,
                .font: Theme.font(14, .regular)
            ]
        )
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        let background = Theme.makeBackgroundView(tableView.bounds)
        tableView.backgroundView = background
        emptyHint.text = "这个收藏夹还是空的"
        emptyHint.textAlignment = .center
        emptyHint.textColor = Theme.textFaint
        emptyHint.font = Theme.font(13, .regular)
        emptyHint.frame = background.bounds
        emptyHint.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        background.addSubview(emptyHint)

        setupPagination()
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

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    // MARK: - 分页

    private var totalPages: Int {
        return max(1, Int(ceil(Double(filteredItems.count) / Double(pageSize))))
    }

    private var pageItems: [FavoriteItem] {
        guard !filteredItems.isEmpty else { return [] }
        let start = (currentPage - 1) * pageSize
        guard start < filteredItems.count else { return [] }
        let end = min(start + pageSize, filteredItems.count)
        return Array(filteredItems[start..<end])
    }

    private func setupPagination() {
        paginationBar.backgroundColor = Theme.card
        paginationBar.isHidden = true
        paginationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(paginationBar)

        let topLine = UIView()
        topLine.backgroundColor = Theme.cardBorder
        topLine.translatesAutoresizingMaskIntoConstraints = false
        paginationBar.addSubview(topLine)

        for button in [prevButton, nextButton] {
            button.tintColor = Theme.textDim
            button.translatesAutoresizingMaskIntoConstraints = false
            paginationBar.addSubview(button)
        }
        prevButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        nextButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        prevButton.addTarget(self, action: #selector(previousPage), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextPage), for: .touchUpInside)

        pagesScroll.showsHorizontalScrollIndicator = false
        pagesScroll.alwaysBounceHorizontal = false
        pagesScroll.translatesAutoresizingMaskIntoConstraints = false
        paginationBar.addSubview(pagesScroll)

        pagesStack.axis = .horizontal
        pagesStack.spacing = 6
        pagesStack.alignment = .center
        pagesStack.translatesAutoresizingMaskIntoConstraints = false
        pagesScroll.addSubview(pagesStack)

        NSLayoutConstraint.activate([
            paginationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            paginationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            paginationBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            paginationBar.heightAnchor.constraint(equalToConstant: 52),

            topLine.leadingAnchor.constraint(equalTo: paginationBar.leadingAnchor),
            topLine.trailingAnchor.constraint(equalTo: paginationBar.trailingAnchor),
            topLine.topAnchor.constraint(equalTo: paginationBar.topAnchor),
            topLine.heightAnchor.constraint(equalToConstant: 0.5),

            prevButton.leadingAnchor.constraint(equalTo: paginationBar.leadingAnchor, constant: 12),
            prevButton.centerYAnchor.constraint(equalTo: paginationBar.centerYAnchor),
            prevButton.widthAnchor.constraint(equalToConstant: 32),
            prevButton.heightAnchor.constraint(equalToConstant: 32),

            nextButton.trailingAnchor.constraint(equalTo: paginationBar.trailingAnchor, constant: -12),
            nextButton.centerYAnchor.constraint(equalTo: paginationBar.centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 32),
            nextButton.heightAnchor.constraint(equalToConstant: 32),

            pagesScroll.leadingAnchor.constraint(equalTo: prevButton.trailingAnchor, constant: 6),
            pagesScroll.trailingAnchor.constraint(equalTo: nextButton.leadingAnchor, constant: -6),
            pagesScroll.topAnchor.constraint(equalTo: paginationBar.topAnchor, constant: 8),
            pagesScroll.bottomAnchor.constraint(equalTo: paginationBar.bottomAnchor, constant: -8),

            pagesStack.leadingAnchor.constraint(equalTo: pagesScroll.contentLayoutGuide.leadingAnchor),
            pagesStack.trailingAnchor.constraint(equalTo: pagesScroll.contentLayoutGuide.trailingAnchor),
            pagesStack.topAnchor.constraint(equalTo: pagesScroll.contentLayoutGuide.topAnchor),
            pagesStack.bottomAnchor.constraint(equalTo: pagesScroll.contentLayoutGuide.bottomAnchor),
            pagesStack.heightAnchor.constraint(equalTo: pagesScroll.frameLayoutGuide.heightAnchor)
        ])
    }

    private func updatePagination() {
        let pages = totalPages
        if currentPage > pages { currentPage = pages }
        if currentPage < 1 { currentPage = 1 }

        let shouldShow = pages > 1 && !filteredItems.isEmpty
        paginationBar.isHidden = !shouldShow
        tableView.contentInset.bottom = shouldShow ? 76 : 24

        pagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard shouldShow else { return }

        for page in 1...pages {
            let button = UIButton(type: .system)
            button.tag = page
            button.setTitle("\(page)", for: .normal)
            button.titleLabel?.font = Theme.font(13, .medium)
            button.layer.cornerRadius = 8
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 32).isActive = true
            button.heightAnchor.constraint(equalToConstant: 32).isActive = true
            button.accessibilityLabel = "第 \(page) 页"
            if page == currentPage {
                button.backgroundColor = Theme.accent
                button.setTitleColor(Theme.onAccent, for: .normal)
            } else {
                button.backgroundColor = .clear
                button.setTitleColor(Theme.textDim, for: .normal)
            }
            button.addTarget(self, action: #selector(pageTapped(_:)), for: .touchUpInside)
            pagesStack.addArrangedSubview(button)
        }

        prevButton.isEnabled = currentPage > 1
        nextButton.isEnabled = currentPage < pages
        prevButton.alpha = prevButton.isEnabled ? 1 : 0.3
        nextButton.alpha = nextButton.isEnabled ? 1 : 0.3

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.view.layoutIfNeeded()
            let index = self.currentPage - 1
            guard index >= 0, index < self.pagesStack.arrangedSubviews.count else { return }
            let button = self.pagesStack.arrangedSubviews[index]
            self.pagesScroll.scrollRectToVisible(button.frame.insetBy(dx: -10, dy: 0), animated: false)
        }
    }

    @objc private func previousPage() {
        setPage(currentPage - 1)
    }

    @objc private func nextPage() {
        setPage(currentPage + 1)
    }

    @objc private func pageTapped(_ sender: UIButton) {
        setPage(sender.tag)
    }

    private func setPage(_ page: Int) {
        let target = min(max(page, 1), totalPages)
        guard target != currentPage else { return }
        currentPage = target
        Haptics.tap()
        tableView.reloadData()
        updatePagination()
        let top = -tableView.adjustedContentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: top), animated: false)
    }

    // MARK: - 数据


    private func loadItems(resetPage: Bool = false) {
        items = FavoriteStore.shared.items(in: folderId)
        applyFilter(resetPage: resetPage)
    }

    private func applyFilter(resetPage: Bool) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { item in
                item.title.localizedCaseInsensitiveContains(query)
                    || item.siteName.localizedCaseInsensitiveContains(query)
                    || item.url.localizedCaseInsensitiveContains(query)
            }
        }
        if resetPage { currentPage = 1 }
        let pages = totalPages
        if currentPage > pages { currentPage = pages }
        if currentPage < 1 { currentPage = 1 }
        emptyHint.text = items.isEmpty
            ? "这个收藏夹还是空的"
            : (filteredItems.isEmpty ? "没有匹配的收藏" : "")
        emptyHint.isHidden = !filteredItems.isEmpty
        tableView.reloadData()
        updatePagination()
    }

    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        loadItems(resetPage: true)
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

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pageItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = pageItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: FavoriteRowCell.reuseID,
                                                 for: indexPath) as! FavoriteRowCell
        cell.configure(emoji: item.siteEmoji,
                       title: item.title,
                       meta: "\(item.siteName) · \(Self.dateText(item.createdAt))")
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let page = pageItems
        guard indexPath.row < page.count else { return }
        let item = page[indexPath.row]
        navigationController?.pushViewController(
            WebViewController(title: item.siteName, urlString: item.url),
            animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let page = pageItems
        guard indexPath.row < page.count else { return nil }
        let item = page[indexPath.row]
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
