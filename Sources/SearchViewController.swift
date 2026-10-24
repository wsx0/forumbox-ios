import UIKit

/// 聚合搜索：两列网格结果 + 筛选
final class SearchViewController: ThreadGridViewController, UISearchBarDelegate {

    private let aggregator = SiteFetchAggregator()
    private let searchController = UISearchController(searchResultsController: nil)
    private var results: [SiteThreadResult] = []
    private var query = ""

    private lazy var moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"),
                                                  style: .plain,
                                                  target: self,
                                                  action: #selector(showMoreMenu))

    deinit {
        aggregator.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "搜索"
        ImageLoader.shared.refreshCookies(force: true)
        setupSearchController()
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.rightBarButtonItem = moreButton
        definesPresentationContext = true
        setHeaderVisible(false)

        onSelect = { [weak self] entry in
            self?.navigationController?.pushViewController(
                WebViewController(title: entry.site.name, urlString: entry.item.url),
                animated: true)
        }
        onRefresh = { [weak self] in
            guard let self = self else { return }
            if self.query.isEmpty {
                self.endRefreshing()
            } else {
                self.startSearch()
            }
        }
        resetToIdle()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            aggregator.cancel()
        }
    }

    // MARK: - 搜索框

    private func setupSearchController() {
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "输入关键词，一次搜遍所有论坛"
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.searchTextField.backgroundColor = Theme.card
        searchController.searchBar.searchTextField.textColor = Theme.text
        searchController.searchBar.searchTextField.tintColor = Theme.accent
        searchController.searchBar.keyboardAppearance = Theme.keyboardAppearance
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        let text = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        query = text
        startSearch()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        resetToIdle()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resetToIdle()
        }
    }

    private func resetToIdle() {
        query = ""
        results = []
        aggregator.cancel()
        extraSummary = nil
        setHeaderVisible(false)
        setChips(sites: [])
        setEntries([])
        setFetching(false)
        endRefreshing()
        showStatus("输入关键词，一次搜遍所有论坛", spinning: false)
    }

    private func startSearch() {
        guard !query.isEmpty else { return }
        let currentQuery = query
        let searchable = Sites.all.filter { $0.searchURL != nil }
        results = searchable.map { SiteThreadResult(site: $0, status: "搜索中…", items: []) }
        setHeaderVisible(true)
        setChips(sites: searchable)
        extraSummary = nil
        setEntries([])
        setFetching(true)
        showStatus("正在搜索各论坛…", spinning: true)

        aggregator.start(sites: Sites.all,
                         needsAutoSearch: true,
                         urlForSite: { site in
                            guard let searchURL = site.searchURL, !searchURL.isEmpty else { return nil }
                            let encoded = currentQuery.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
                            return searchURL + "#fbq=" + encoded
                         },
                         update: { [weak self] result in
                            guard let self = self else { return }
                            if let index = self.results.firstIndex(where: { $0.site.name == result.site.name }) {
                                self.results[index] = result
                            }
                            self.rebuildAndShow()
                            self.hideStatus()
                         },
                         finished: { [weak self] in
                            guard let self = self else { return }
                            self.setFetching(false)
                            self.endRefreshing()
                            ImageLoader.shared.refreshCookies(force: true)
                            self.rebuildAndShow()
                            if self.entries.isEmpty {
                                self.showStatus("没有搜到结果，换个关键词试试", spinning: false)
                            } else {
                                self.hideStatus()
                                // cookie 同步完成后重试一次缩略图
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                                    self?.collectionView.reloadData()
                                }
                            }
                         })
    }

    private func rebuildAndShow() {
        extraSummary = FeedPipeline.failedStatusText(results, pendingStatus: "搜索中…")
        setChips(sites: results.map { $0.site })
        setEntries(FeedPipeline.entries(from: results))
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
}
