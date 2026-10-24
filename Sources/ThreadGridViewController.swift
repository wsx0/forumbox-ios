import UIKit

/// 精华 / 搜索共用的两列网格基类
class ThreadGridViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    let collectionView: UICollectionView
    let chipsView = FilterChipsView()
    let summaryLabel = UILabel()
    let statusView = FeedStatusView()

    private let headerContainer = UIView()
    private var headerHeightConstraint: NSLayoutConstraint!

    private(set) var entries: [FeedEntry] = []
    private(set) var chipsSites: [Site] = []
    private(set) var filterSiteName: String?
    private(set) var isFetching = false
    var extraSummary: String?

    var onSelect: ((FeedEntry) -> Void)?
    var onRefresh: (() -> Void)?

    private var filteredEntries: [FeedEntry] {
        guard let name = filterSiteName else { return entries }
        return entries.filter { $0.site.name == name }
    }

    init() {
        collectionView = UICollectionView(frame: .zero,
                                          collectionViewLayout: ThreadGridViewController.makeLayout())
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func makeLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5),
                                              heightDimension: .absolute(198))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 6, bottom: 5, trailing: 6)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(198))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 24, trailing: 10)
        return UICollectionViewCompositionalLayout(section: section)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.bgTop

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ThreadGridCell.self, forCellWithReuseIdentifier: ThreadGridCell.reuseID)
        collectionView.backgroundView = Theme.makeBackgroundView(collectionView.bounds)
        collectionView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 24, right: 0)
        view.addSubview(collectionView)

        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.backgroundColor = .clear
        view.addSubview(headerContainer)

        chipsView.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(chipsView)

        summaryLabel.font = Theme.rounded(11.5, .medium)
        summaryLabel.textColor = Theme.textFaint
        summaryLabel.lineBreakMode = .byTruncatingTail
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(summaryLabel)

        statusView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusView)
        statusView.isHidden = true

        headerHeightConstraint = headerContainer.heightAnchor.constraint(equalToConstant: 62)
        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerHeightConstraint,

            chipsView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 4),
            chipsView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            chipsView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            chipsView.heightAnchor.constraint(equalToConstant: Design.chipHeight),

            summaryLabel.topAnchor.constraint(equalTo: chipsView.bottomAnchor, constant: 8),
            summaryLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: Design.hPad),
            summaryLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -Design.hPad),
            summaryLabel.heightAnchor.constraint(equalToConstant: 16),

            collectionView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            statusView.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            statusView.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor),
            statusView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            statusView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])

        let refresh = UIRefreshControl()
        refresh.tintColor = Theme.accent
        refresh.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        collectionView.refreshControl = refresh

        chipsView.onSelect = { [weak self] index in
            guard let self = self else { return }
            if index == 0 {
                self.filterSiteName = nil
            } else if index - 1 < self.chipsSites.count {
                self.filterSiteName = self.chipsSites[index - 1].name
            }
            self.collectionView.reloadData()
            self.refreshSummary()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.backgroundView?.frame = collectionView.bounds
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    // MARK: - 状态更新

    @objc private func pullToRefresh() {
        if let onRefresh = onRefresh {
            onRefresh()
        } else {
            collectionView.refreshControl?.endRefreshing()
        }
    }

    func endRefreshing() {
        collectionView.refreshControl?.endRefreshing()
    }

    func setHeaderVisible(_ visible: Bool) {
        headerContainer.isHidden = !visible
        headerHeightConstraint.constant = visible ? 62 : 0
        view.setNeedsLayout()
    }

    func setChips(sites: [Site]) {
        chipsSites = sites
        if let name = filterSiteName, !sites.contains(where: { $0.name == name }) {
            filterSiteName = nil
        }
        var items = [FilterChipsView.Item(title: "全部")]
        for site in sites {
            items.append(FilterChipsView.Item(title: "\(site.emoji) \(site.name)"))
        }
        let selected: Int
        if let name = filterSiteName,
           let index = sites.firstIndex(where: { $0.name == name }) {
            selected = index + 1
        } else {
            selected = 0
        }
        chipsView.configure(items: items, selected: selected)
    }

    func setEntries(_ newEntries: [FeedEntry]) {
        entries = newEntries
        collectionView.reloadData()
        refreshSummary()
        if !entries.isEmpty {
            hideStatus()
        }
    }

    func setFetching(_ fetching: Bool) {
        isFetching = fetching
        refreshSummary()
    }

    func refreshSummary() {
        let visible = filteredEntries.count
        guard visible > 0 else {
            summaryLabel.text = isFetching ? "正在加载…" : ""
            return
        }
        let siteCount = Set(entries.map { $0.site.name }).count
        var text = "共 \(visible) 条 · 来自 \(siteCount) 个论坛"
        if let extra = extraSummary, !extra.isEmpty {
            text += " · \(extra)"
        }
        summaryLabel.text = text
    }

    func showStatus(_ text: String, spinning: Bool) {
        statusView.show(text, spinning: spinning)
    }

    func hideStatus() {
        statusView.hide()
    }

    // MARK: - 数据源 / 交互

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredEntries.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThreadGridCell.reuseID,
                                                      for: indexPath) as! ThreadGridCell
        cell.configure(entry: filteredEntries[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard indexPath.row < filteredEntries.count else { return }
        Haptics.tap()
        onSelect?(filteredEntries[indexPath.row])
    }

    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.row < filteredEntries.count else { return nil }
        let entry = filteredEntries[indexPath.row]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let open = UIAction(title: "打开",
                                image: UIImage(systemName: "arrow.up.right.square")) { _ in
                self?.onSelect?(entry)
            }
            let favorite = UIAction(title: "收藏",
                                    image: UIImage(systemName: "star")) { _ in
                FavoriteStore.shared.add(title: entry.item.title,
                                         url: entry.item.url,
                                         siteName: entry.site.name,
                                         siteEmoji: entry.site.emoji,
                                         folderId: nil)
                Haptics.success()
            }
            return UIMenu(children: [open, favorite])
        }
    }
}
