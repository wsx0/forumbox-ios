import UIKit

/// 精华页：两列网格 + 筛选 chips
final class DigestViewController: ThreadGridViewController {

    private let aggregator = SiteFetchAggregator()
    private var results: [SiteThreadResult] = []
    private var sitesObserver: NSObjectProtocol?

    private lazy var themeButton = ThemePicker.makeButton(target: self, action: #selector(showThemePicker))

    deinit {
        if let observer = sitesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        aggregator.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "精华"
        navigationItem.leftBarButtonItem = themeButton

        onSelect = { [weak self] entry in
            self?.navigationController?.pushViewController(
                WebViewController(title: entry.site.name, urlString: entry.item.url),
                animated: true)
        }
        onRefresh = { [weak self] in
            self?.loadDigest()
        }

        // 站点增删改后自动刷新
        sitesObserver = NotificationCenter.default.addObserver(forName: .sitesChanged,
                                                               object: nil,
                                                               queue: .main) { [weak self] _ in
            self?.loadDigest()
        }

        loadDigest()
    }

    @objc private func showThemePicker() {
        ThemePicker.present(from: self, sourceItem: themeButton)
    }

    private func loadDigest() {
        guard !isFetching else { return }
        let digestSites = Sites.all.filter { $0.digestURL != nil }
        guard !digestSites.isEmpty else {
            results = []
            setChips(sites: [])
            setEntries([])
            setFetching(false)
            endRefreshing()
            showStatus("还没有可抓取精华的论坛\n\n去「论坛」页 → 编辑站点 → 填写「精华页地址」", spinning: false)
            return
        }

        results = digestSites.map { SiteThreadResult(site: $0, status: "抓取中…", items: []) }
        setChips(sites: digestSites)
        extraSummary = nil
        setEntries([])
        setFetching(true)
        showStatus("正在抓取各论坛精华…", spinning: true)

        aggregator.start(sites: digestSites,
                         needsAutoSearch: false,
                         urlForSite: { $0.digestURL },
                         update: { [weak self] result in
                            guard let self = self else { return }
                            if let index = self.results.firstIndex(where: { $0.site.name == result.site.name }) {
                                self.results[index] = result
                            }
                            self.extraSummary = FeedPipeline.failedStatusText(self.results)
                            self.setChips(sites: self.results.map { $0.site })
                            self.setEntries(FeedPipeline.entries(from: self.results))
                         },
                         finished: { [weak self] in
                            guard let self = self else { return }
                            self.setFetching(false)
                            self.endRefreshing()
                            if self.entries.isEmpty {
                                self.showStatus("暂时没抓到精华，下拉刷新试试", spinning: false)
                            } else {
                                self.hideStatus()
                            }
                         })
    }
}
