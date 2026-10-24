import UIKit

/// 精华页：清爽的"全部论坛"信息流 + 筛选 chips
final class DigestViewController: UITableViewController {

    private let aggregator = SiteFetchAggregator()
    private let chipsView = FilterChipsView()
    private let statusView = FeedStatusView()
    private let summaryLabel = UILabel()

    private var results: [SiteThreadResult] = []
    private var entries: [FeedEntry] = []
    private var filterSiteName: String?
    private var isFetching = false

    private lazy var themeButton = UIBarButtonItem(image: UIImage(systemName: "paintpalette"),
                                                   style: .plain,
                                                   target: self,
                                                   action: #selector(showThemePicker))

    private var filteredEntries: [FeedEntry] {
        guard let name = filterSiteName else { return entries }
        return entries.filter { $0.site.name == name }
    }

    deinit {
        aggregator.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "精华"
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = Design.feedRowHeight
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 24, right: 0)
        tableView.register(ThreadCell.self, forCellReuseIdentifier: "ThreadCell")
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.leftBarButtonItem = themeButton
        navigationController?.navigationBar.prefersLargeTitles = false
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)

        setupHeader()
        setupStatusView()
        setupRefresh()

        loadDigest()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
        if let header = tableView.tableHeaderView {
            header.frame.size.width = tableView.bounds.width
            chipsView.frame = CGRect(x: 0, y: 4, width: header.bounds.width, height: Design.chipHeight)
            summaryLabel.frame = CGRect(x: Design.hPad, y: 42,
                                        width: header.bounds.width - Design.hPad * 2, height: 16)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    // MARK: - 构建

    private func setupHeader() {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 66))
        header.backgroundColor = .clear
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
        header.addSubview(chipsView)
        header.addSubview(summaryLabel)
        tableView.tableHeaderView = header
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

    @objc private func showThemePicker() {
        ThemePicker.present(from: self, sourceItem: themeButton)
    }

    @objc private func pullRefresh() {
        aggregator.cancel()
        isFetching = false
        loadDigest()
    }

    // MARK: - 抓取

    private func loadDigest() {
        guard !isFetching else { return }
        let digestSites = Sites.all.filter { $0.digestURL != nil }
        guard !digestSites.isEmpty else {
            results = []
            entries = []
            filterSiteName = nil
            tableView.reloadData()
            updateSummary()
            tableView.refreshControl?.endRefreshing()
            statusView.show("还没有可抓取精华的论坛\n\n去「论坛」页 → 编辑站点 → 填写「精华页地址」", spinning: false)
            return
        }

        isFetching = true
        filterSiteName = nil
        results = digestSites.map { SiteThreadResult(site: $0, status: "抓取中…", items: []) }
        entries = interleavedEntries(results)
        updateSummary()
        tableView.reloadData()
        if entries.isEmpty {
            statusView.show("正在抓取各论坛精华…", spinning: true)
        }

        aggregator.start(sites: digestSites,
                         needsAutoSearch: false,
                         urlForSite: { $0.digestURL },
                         update: { [weak self] result in
                            guard let self = self else { return }
                            if let index = self.results.firstIndex(where: { $0.site.name == result.site.name }) {
                                self.results[index] = result
                            }
                            self.entries = interleavedEntries(self.results)
                            self.refreshChrome()
                            if !self.entries.isEmpty {
                                self.statusView.hide()
                            }
                         },
                         finished: { [weak self] in
                            guard let self = self else { return }
                            self.isFetching = false
                            self.tableView.refreshControl?.endRefreshing()
                            self.refreshChrome()
                            if self.entries.isEmpty {
                                self.statusView.show("暂时没抓到精华，下拉刷新试试", spinning: false)
                            } else {
                                self.statusView.hide()
                            }
                         })
    }

    private func refreshChrome() {
        if let name = filterSiteName, !results.contains(where: { $0.site.name == name }) {
            filterSiteName = nil
        }
        var items = [FilterChipsView.Item(title: "全部")]
        for result in results {
            items.append(FilterChipsView.Item(title: "\(result.site.emoji) \(result.site.name)"))
        }
        chipsView.configure(items: items, selected: selectedChipIndex())
        updateSummary()
        tableView.reloadData()
    }

    private func selectedChipIndex() -> Int {
        guard let name = filterSiteName,
              let index = results.firstIndex(where: { $0.site.name == name }) else { return 0 }
        return index + 1
    }

    private func updateSummary() {
        let visible = filteredEntries.count
        if visible == 0 {
            summaryLabel.text = isFetching ? "正在抓取各论坛精华…" : "暂时没有精华内容"
        } else {
            let siteCount = Set(entries.map { $0.site.name }).count
            var text = "共 \(visible) 条 · 来自 \(siteCount) 个论坛"
            let failed = results.filter { $0.items.isEmpty && $0.status != "抓取中…" }
            if !failed.isEmpty {
                let detail = failed.prefix(2).map { "\($0.site.name) \($0.status)" }.joined(separator: "，")
                text += " · \(detail)"
            }
            summaryLabel.text = text
        }
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
