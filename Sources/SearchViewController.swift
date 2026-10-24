import UIKit

/// 聚合搜索：一个搜索框 + 清爽的合并结果流
final class SearchViewController: UITableViewController, UISearchBarDelegate {

    private let aggregator = SearchAggregator()
    private let chipsView = FilterChipsView()
    private let statusView = FeedStatusView()
    private let summaryLabel = UILabel()
    private let searchController = UISearchController(searchResultsController: nil)
    private let headerContainer = UIView()

    private var results: [SearchAggregator.SiteResult] = []
    private var entries: [FeedEntry] = []
    private var filterSiteName: String?
    private var query = ""
    private var isSearching = false

    private lazy var moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"),
                                                  style: .plain,
                                                  target: self,
                                                  action: #selector(showMoreMenu))

    private var filteredEntries: [FeedEntry] {
        guard let name = filterSiteName else { return entries }
        return entries.filter { $0.site.name == name }
    }

    deinit {
        aggregator.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "搜索"
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = Design.feedRowHeight
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 24, right: 0)
        tableView.register(ThreadCell.self, forCellReuseIdentifier: "ThreadCell")
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.rightBarButtonItem = moreButton
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)

        setupSearchController()
        setupHeader()
        setupStatusView()
        setupRefresh()
        updateIdleState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
        layoutHeader()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            aggregator.cancel()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    // MARK: - 构建

    private func setupSearchController() {
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "输入关键词，一次搜遍所有论坛"
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.searchTextField.backgroundColor = Theme.card
        searchController.searchBar.searchTextField.textColor = Theme.text
        searchController.searchBar.searchTextField.tintColor = Theme.accent
        searchController.searchBar.keyboardAppearance = Theme.keyboardAppearance
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupHeader() {
        headerContainer.backgroundColor = .clear
        chipsView.onSelect = { [weak self] index in
            guard let self = self else { return }
            if index == 0 {
                self.filterSiteName = nil
            } else if index - 1 < self.results.count {
                self.filterSiteName = self.results[index - 1].site.name
            }
            self.tableView.reloadData()
            self.updateSummary()
        }
        summaryLabel.font = Theme.rounded(11.5, .medium)
        summaryLabel.textColor = Theme.textFaint
        summaryLabel.lineBreakMode = .byTruncatingTail
        headerContainer.addSubview(chipsView)
        headerContainer.addSubview(summaryLabel)
        layoutHeader()
    }

    private func layoutHeader() {
        let visible = !query.isEmpty
        let width = view.bounds.width
        let height: CGFloat = visible ? 66 : 0
        headerContainer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        chipsView.frame = CGRect(x: 0, y: 4, width: width, height: Design.chipHeight)
        summaryLabel.frame = CGRect(x: Design.hPad, y: 42, width: width - Design.hPad * 2, height: 16)
        chipsView.isHidden = !visible
        summaryLabel.isHidden = !visible
        if tableView.tableHeaderView !== headerContainer {
            tableView.tableHeaderView = headerContainer
        }
    }

    private func setupStatusView() {
        statusView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusView)
        NSLayoutConstraint.activate([
            statusView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            statusView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
        statusView.isHidden = true
    }

    private func setupRefresh() {
        let refresh = UIRefreshControl()
        refresh.tintColor = Theme.accent
        refresh.addTarget(self, action: #selector(pullRefresh), for: .valueChanged)
        tableView.refreshControl = refresh
    }

    @objc private func pullRefresh() {
        if query.isEmpty {
            tableView.refreshControl?.endRefreshing()
        } else {
            startSearch()
        }
    }

    // MARK: - 搜索动作

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        let text = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        query = text
        startSearch()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        resetSearch()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resetSearch()
        }
    }

    private func resetSearch() {
        query = ""
        results = []
        entries = []
        filterSiteName = nil
        aggregator.cancel()
        isSearching = false
        tableView.refreshControl?.endRefreshing()
        layoutHeader()
        tableView.reloadData()
        statusView.show("输入关键词，一次搜遍所有论坛", spinning: false)
    }

    private func startSearch() {
        guard !query.isEmpty else { return }
        isSearching = true
        filterSiteName = nil
        let searchable = Sites.all.filter { $0.searchURL != nil }
        results = searchable.map { SearchAggregator.SiteResult(site: $0, status: "搜索中…", items: []) }
        entries = []
        layoutHeader()
        refreshChips()
        updateSummary()
        tableView.reloadData()
        statusView.show("正在搜索各论坛…", spinning: true)

        aggregator.search(query: query, sites: Sites.all, update: { [weak self] result in
            guard let self = self else { return }
            if let index = self.results.firstIndex(where: { $0.site.name == result.site.name }) {
                self.results[index] = result
            }
            self.rebuildEntries()
            self.refreshChips()
            self.updateSummary()
            self.tableView.reloadData()
            if !self.entries.isEmpty {
                self.statusView.hide()
            }
        }, finished: { [weak self] in
            guard let self = self else { return }
            self.isSearching = false
            self.tableView.refreshControl?.endRefreshing()
            self.rebuildEntries()
            self.refreshChips()
            self.updateSummary()
            self.tableView.reloadData()
            if self.entries.isEmpty {
                self.statusView.show("没有搜到结果，换个关键词试试", spinning: false)
            } else {
                self.statusView.hide()
            }
        })
    }

    private func rebuildEntries() {
        let siteResults = results.map { result in
            SiteThreadResult(site: result.site,
                             status: result.status,
                             items: result.items)
        }
        entries = interleavedEntries(siteResults)
    }

    private func refreshChips() {
        if let name = filterSiteName, !results.contains(where: { $0.site.name == name }) {
            filterSiteName = nil
        }
        var items = [FilterChipsView.Item(title: "全部")]
        for result in results {
            items.append(FilterChipsView.Item(title: "\(result.site.emoji) \(result.site.name)"))
        }
        chipsView.configure(items: items, selected: selectedChipIndex())
    }

    private func selectedChipIndex() -> Int {
        guard let name = filterSiteName,
              let index = results.firstIndex(where: { $0.site.name == name }) else { return 0 }
        return index + 1
    }

    private func updateSummary() {
        guard !query.isEmpty else {
            summaryLabel.text = nil
            return
        }
        let visible = filteredEntries.count
        if visible == 0 {
            summaryLabel.text = isSearching ? "正在搜索各论坛…" : "没有搜到结果"
            return
        }
        let siteCount = Set(entries.map { $0.site.name }).count
        var text = "共 \(visible) 条 · 来自 \(siteCount) 个论坛"
        let failed = results.filter { $0.items.isEmpty && $0.status != "搜索中…" }
        if !failed.isEmpty {
            let detail = failed.prefix(2).map { "\($0.site.name) \($0.status)" }.joined(separator: "，")
            text += " · \(detail)"
        }
        summaryLabel.text = text
    }

    private func updateIdleState() {
        layoutHeader()
        tableView.reloadData()
        if query.isEmpty {
            statusView.show("输入关键词，一次搜遍所有论坛", spinning: false)
        } else if isSearching {
            statusView.show("正在搜索各论坛…", spinning: true)
        } else if entries.isEmpty {
            statusView.show("没有搜到结果，换个关键词试试", spinning: false)
        } else {
            statusView.hide()
        }
    }

    @objc private func showMoreMenu() {
        guard !query.isEmpty else {
            presentNotice("先输入关键词搜索一次")
            return
        }
        let searchable = Sites.all.filter { $0.searchURL != nil }
        let sheet = UIAlertController(title: "逐站打开搜索页",
                                      message: "在当前论坛里搜索「\(query)」",
                                      preferredStyle: .actionSheet)
        for site in searchable {
            sheet.addAction(UIAlertAction(title: "\(site.emoji) \(site.name)", style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.navigationController?.pushViewController(
                    WebViewController(site: site, searchQuery: self.query),
                    animated: true)
            })
        }
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

    // MARK: - 表格

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredEntries.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ThreadCell", for: indexPath) as! ThreadCell
        let entry = filteredEntries[indexPath.row]
        cell.configure(emoji: entry.site.emoji,
                       title: entry.item.title,
                       meta: entry.site.name,
                       thumbURL: entry.item.thumbURL,
                       referer: entry.site.url)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < filteredEntries.count else { return }
        let entry = filteredEntries[indexPath.row]
        Haptics.tap()
        navigationController?.pushViewController(
            WebViewController(title: entry.site.name, urlString: entry.item.url),
            animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < filteredEntries.count else { return nil }
        let entry = filteredEntries[indexPath.row]
        let favorite = UIContextualAction(style: .normal, title: "收藏") { _, _, completion in
            FavoriteStore.shared.add(title: entry.item.title,
                                     url: entry.item.url,
                                     siteName: entry.site.name,
                                     siteEmoji: entry.site.emoji,
                                     folderId: nil)
            Haptics.success()
            completion(true)
        }
        favorite.backgroundColor = Theme.accent
        return UISwipeActionsConfiguration(actions: [favorite])
    }
}
