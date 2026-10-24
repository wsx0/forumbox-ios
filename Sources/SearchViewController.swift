import UIKit

final class SearchViewController: UITableViewController, UISearchBarDelegate {

    private struct ManualRow {
        let title: String
        let subtitle: String
        let site: Site
        let searchQuery: String?
    }

    private let searchBar = UISearchBar()
    private let hintLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let aggregator = SearchAggregator()

    private var query = ""
    private var sections: [SearchAggregator.SiteResult] = []
    private var manualRows: [ManualRow] = []
    private var isSearching = false
    private var hasFocusedOnce = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "聚合搜索"
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 78
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 24, right: 0)
        tableView.keyboardDismissMode = .onDrag
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: "SearchResultCell")
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)

        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 64))
        header.backgroundColor = .clear
        searchBar.frame = CGRect(x: 6, y: 4, width: header.bounds.width - 12, height: 56)
        searchBar.autoresizingMask = [.flexibleWidth]
        searchBar.searchBarStyle = .minimal
        searchBar.barStyle = .black
        searchBar.placeholder = "输入关键词，合并搜索所有论坛"
        searchBar.delegate = self
        searchBar.searchTextField.textColor = .white
        searchBar.searchTextField.backgroundColor = Theme.card
        searchBar.searchTextField.layer.cornerRadius = 12
        searchBar.searchTextField.clipsToBounds = true
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(
            string: "输入关键词，合并搜索所有论坛",
            attributes: [.foregroundColor: Theme.textFaint])
        searchBar.keyboardAppearance = .dark
        searchBar.returnKeyType = .search
        header.addSubview(searchBar)
        tableView.tableHeaderView = header

        spinner.color = Theme.accent

        hintLabel.text = "输入关键词后点「搜索」，\nApp 会在各论坛同时搜索，再把结果合并到一个列表。"
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
        hintLabel.textColor = Theme.textFaint
        hintLabel.font = Theme.rounded(14, .medium)
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)
        tableView.backgroundView?.addSubview(hintLabel)
        hintLabel.frame = tableView.bounds
        hintLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let background = tableView.backgroundView {
            background.frame = tableView.bounds
            hintLabel.frame = background.bounds
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasFocusedOnce {
            hasFocusedOnce = true
            searchBar.becomeFirstResponder()
        }
    }

    deinit {
        aggregator.cancel()
    }

    // MARK: - 搜索

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        startSearch()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            query = ""
            isSearching = false
            sections.removeAll()
            manualRows.removeAll()
            aggregator.cancel()
            tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)
            tableView.backgroundView?.addSubview(hintLabel)
            updateSpinner()
            tableView.reloadData()
        }
    }

    private func startSearch() {
        let text = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        query = text
        isSearching = true
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)
        sections = Sites.all.filter { $0.searchURL != nil }.map {
            SearchAggregator.SiteResult(site: $0, status: "搜索中…", items: [])
        }
        manualRows = buildManualRows()
        updateSpinner()
        tableView.reloadData()

        aggregator.search(query: query, sites: Sites.all, update: { [weak self] result in
            guard let self = self else { return }
            if let index = self.sections.firstIndex(where: { $0.site.name == result.site.name }) {
                self.sections[index] = result
            } else {
                self.sections.append(result)
            }
            self.tableView.reloadData()
        }, finished: { [weak self] in
            guard let self = self else { return }
            self.isSearching = false
            self.updateSpinner()
            self.tableView.reloadData()
        })
    }

    private func updateSpinner() {
        if isSearching {
            spinner.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        } else {
            spinner.stopAnimating()
            navigationItem.rightBarButtonItem = nil
        }
    }

    private func buildManualRows() -> [ManualRow] {
        var rows: [ManualRow] = []
        for site in Sites.all {
            guard site.searchURL != nil else { continue }
            rows.append(ManualRow(title: "在 \(site.name) 搜索「\(query)」",
                                  subtitle: site.note,
                                  site: site,
                                  searchQuery: query))
        }
        let bingQuery = Self.bingAggregateQuery(query)
        let encoded = bingQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bingSite = Site(name: "必应聚合搜索", note: "一次搜遍全部论坛",
                            url: "https://www.bing.com/search?q=" + encoded, searchURL: nil)
        rows.append(ManualRow(title: "必应聚合：一次搜全部论坛",
                              subtitle: "站内搜索不可用时用这个兜底",
                              site: bingSite,
                              searchQuery: nil))
        return rows
    }

    private static func bingAggregateQuery(_ keyword: String) -> String {
        let domains = Sites.all.compactMap { site -> String? in
            guard let host = URL(string: site.url)?.host, !host.isEmpty else { return nil }
            return "site:\(host)"
        }
        return "(" + domains.joined(separator: " OR ") + ") " + keyword
    }

    // MARK: - 表格

    override func numberOfSections(in tableView: UITableView) -> Int {
        return query.isEmpty ? 0 : sections.count + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < sections.count {
            return max(1, sections[section].items.count)
        }
        return manualRows.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        let label = UILabel()
        label.font = Theme.rounded(12, .semibold)
        label.textColor = Theme.textFaint
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = sectionTitle(section)
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

    private func sectionTitle(_ section: Int) -> String {
        if section < sections.count {
            let result = sections[section]
            return "\(result.site.emoji) \(result.site.name) · \(result.status)"
        }
        return "✦ 手动打开各站搜索"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        if indexPath.section < sections.count {
            let result = sections[indexPath.section]
            if result.items.isEmpty {
                cell.configure(title: result.status, subtitle: "可手动打开该站搜索，或稍后重试")
            } else {
                let item = result.items[indexPath.row]
                cell.configure(title: item.title, subtitle: result.site.name)
            }
        } else {
            let row = manualRows[indexPath.row]
            cell.configure(title: row.title, subtitle: row.subtitle)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section < sections.count {
            let result = sections[indexPath.section]
            guard !result.items.isEmpty else { return }
            let item = result.items[indexPath.row]
            let targetSite = Site(name: result.site.name, note: "", url: item.url, searchURL: nil, emoji: result.site.emoji)
            navigationController?.pushViewController(WebViewController(site: targetSite), animated: true)
        } else {
            let row = manualRows[indexPath.row]
            let controller = WebViewController(site: row.site, searchQuery: row.searchQuery)
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}

final class SearchResultCell: UITableViewCell {

    private let container = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        container.backgroundColor = Theme.card
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 1
        container.layer.borderColor = Theme.cardBorder.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        titleLabel.font = Theme.rounded(15.5, .semibold)
        titleLabel.textColor = Theme.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.font = .systemFont(ofSize: 10.5, weight: .medium)
        subtitleLabel.textColor = Theme.textFaint
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.lineBreakMode = .byTruncatingTail

        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 15),

            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 7)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}
