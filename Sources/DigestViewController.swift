import UIKit

/// 全部精华：按站点分组展示各论坛精华帖
final class DigestViewController: UITableViewController {

    private let aggregator = SiteFetchAggregator()
    private var sections: [SiteThreadResult] = []
    private var isFetching = false
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var hasLoaded = false

    deinit {
        aggregator.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "全部精华"
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 78
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 24, right: 0)
        tableView.register(CardCell.self, forCellReuseIdentifier: "CardCell")
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)
        navigationItem.backButtonDisplayMode = .minimal

        let refresh = UIRefreshControl()
        refresh.tintColor = Theme.accent
        refresh.addTarget(self, action: #selector(pullRefresh), for: .valueChanged)
        tableView.refreshControl = refresh

        spinner.color = Theme.accent
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasLoaded {
            hasLoaded = true
            loadDigest()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
    }

    @objc private func pullRefresh() {
        aggregator.cancel()
        isFetching = false
        loadDigest()
    }

    private func loadDigest() {
        guard !isFetching else { return }
        isFetching = true
        sections = Sites.all.filter { $0.digestURL != nil }.map {
            SiteThreadResult(site: $0, status: "抓取中…", items: [])
        }
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        tableView.reloadData()

        aggregator.start(sites: Sites.all,
                         needsAutoSearch: false,
                         urlForSite: { $0.digestURL },
                         update: { [weak self] result in
                            guard let self = self else { return }
                            if let index = self.sections.firstIndex(where: { $0.site.name == result.site.name }) {
                                self.sections[index] = result
                                self.tableView.reloadSections(IndexSet(integer: index), with: .none)
                            }
                         },
                         finished: { [weak self] in
                            guard let self = self else { return }
                            self.isFetching = false
                            self.spinner.stopAnimating()
                            self.navigationItem.rightBarButtonItem = nil
                            self.tableView.refreshControl?.endRefreshing()
                            self.tableView.reloadData()
                         })
    }

    // MARK: - 表格

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < sections.count else { return 0 }
        return max(1, sections[section].items.count)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        let label = UILabel()
        label.font = Theme.rounded(12, .semibold)
        label.textColor = Theme.textFaint
        label.translatesAutoresizingMaskIntoConstraints = false
        if section < sections.count {
            let result = sections[section]
            label.text = "\(result.site.emoji) \(result.site.name) · \(result.status)"
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
        return 32
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < sections.count else {
            return tableView.dequeueCard(for: indexPath, model: CardCell.Model(
                emoji: "🍃", title: "没有数据", subtitle: "", detail: nil, showsChevron: false))
        }
        let result = sections[indexPath.section]
        if result.items.isEmpty {
            return tableView.dequeueCard(for: indexPath, model: CardCell.Model(
                emoji: "⏳",
                title: result.status,
                subtitle: "下拉可刷新",
                detail: nil,
                showsChevron: false))
        }
        let item = result.items[indexPath.row]
        return tableView.dequeueCard(for: indexPath, model: CardCell.Model(
            emoji: result.site.emoji,
            title: item.title,
            subtitle: result.site.name,
            detail: nil,
            showsChevron: true))
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section < sections.count else { return }
        let result = sections[indexPath.section]
        guard !result.items.isEmpty else { return }
        let item = result.items[indexPath.row]
        navigationController?.pushViewController(
            WebViewController(title: result.site.name, urlString: item.url),
            animated: true)
    }
}
