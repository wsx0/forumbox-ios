import UIKit

/// 精华页：按论坛分组展示各站精华帖
final class DigestViewController: UITableViewController {

    private let aggregator = SiteFetchAggregator()
    private var sections: [SiteThreadResult] = []
    private var isFetching = false
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let emptyHint = UILabel()

    private lazy var themeButton = UIBarButtonItem(image: UIImage(systemName: "paintpalette"),
                                                   style: .plain,
                                                   target: self,
                                                   action: #selector(showThemePicker))

    deinit {
        aggregator.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "精华"
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 78
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 24, right: 0)
        tableView.register(CardCell.self, forCellReuseIdentifier: "CardCell")
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.leftBarButtonItem = themeButton
        navigationController?.navigationBar.prefersLargeTitles = false

        let background = Theme.makeBackgroundView(tableView.bounds)
        tableView.backgroundView = background
        emptyHint.text = "还没有可抓取精华的论坛\n\n去「论坛」页 → 编辑站点 → 填写「精华页地址」"
        emptyHint.numberOfLines = 0
        emptyHint.textAlignment = .center
        emptyHint.textColor = Theme.textFaint
        emptyHint.font = Theme.rounded(14, .medium)
        emptyHint.frame = background.bounds
        emptyHint.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        background.addSubview(emptyHint)

        let refresh = UIRefreshControl()
        refresh.tintColor = Theme.accent
        refresh.addTarget(self, action: #selector(pullRefresh), for: .valueChanged)
        tableView.refreshControl = refresh

        spinner.color = Theme.accent
        loadDigest()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
        if let background = tableView.backgroundView {
            emptyHint.frame = background.bounds
        }
    }

    @objc private func showThemePicker() {
        ThemePicker.present(from: self, sourceItem: themeButton)
    }

    @objc private func pullRefresh() {
        aggregator.cancel()
        isFetching = false
        loadDigest()
    }

    private func loadDigest() {
        guard !isFetching else { return }
        let digestSites = Sites.all.filter { $0.digestURL != nil }
        guard !digestSites.isEmpty else {
            sections = []
            isFetching = false
            emptyHint.isHidden = false
            tableView.refreshControl?.endRefreshing()
            tableView.reloadData()
            return
        }
        isFetching = true
        emptyHint.isHidden = true
        sections = digestSites.map { SiteThreadResult(site: $0, status: "抓取中…", items: []) }
        spinner.startAnimating()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        tableView.reloadData()

        aggregator.start(sites: digestSites,
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
                            self.emptyHint.isHidden = !self.sections.isEmpty
                            self.tableView.reloadData()
                         })
    }

    // MARK: - 表格

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

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

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section < sections.count else { return nil }
        let result = sections[indexPath.section]
        guard !result.items.isEmpty, indexPath.row < result.items.count else { return nil }
        let item = result.items[indexPath.row]
        let favorite = UIContextualAction(style: .normal, title: "收藏") { _, _, completion in
            FavoriteStore.shared.add(title: item.title,
                                     url: item.url,
                                     siteName: result.site.name,
                                     siteEmoji: result.site.emoji,
                                     folderId: nil)
            completion(true)
        }
        favorite.backgroundColor = Theme.accent
        return UISwipeActionsConfiguration(actions: [favorite])
    }
}
