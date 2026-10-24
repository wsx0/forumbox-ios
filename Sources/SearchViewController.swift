import UIKit

final class SearchViewController: UITableViewController, UISearchBarDelegate {

    private struct SearchItem {
        let title: String
        let subtitle: String
        let site: Site
        let searchQuery: String?
    }

    private let searchBar = UISearchBar()
    private let hintLabel = UILabel()
    private let bgColor = UIColor(red: 11/255, green: 18/255, blue: 32/255, alpha: 1)
    private var query = ""
    private var items: [SearchItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "聚合搜索"
        view.backgroundColor = bgColor
        tableView.backgroundColor = bgColor
        tableView.separatorStyle = .none
        tableView.rowHeight = 78
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.keyboardDismissMode = .onDrag
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: "SearchResultCell")

        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 64))
        header.backgroundColor = bgColor
        searchBar.frame = CGRect(x: 6, y: 4, width: header.bounds.width - 12, height: 56)
        searchBar.autoresizingMask = [.flexibleWidth]
        searchBar.searchBarStyle = .minimal
        searchBar.barStyle = .black
        searchBar.placeholder = "输入关键词，搜遍 7 个论坛"
        searchBar.delegate = self
        searchBar.searchTextField.textColor = .white
        searchBar.searchTextField.backgroundColor = UIColor(red: 18/255, green: 30/255, blue: 53/255, alpha: 1)
        searchBar.searchTextField.layer.cornerRadius = 10
        searchBar.searchTextField.clipsToBounds = true
        searchBar.keyboardAppearance = .dark
        searchBar.returnKeyType = .search
        header.addSubview(searchBar)
        tableView.tableHeaderView = header

        hintLabel.text = "输入关键词后点「搜索」，\n下方会列出各论坛的搜索入口。"
        hintLabel.numberOfLines = 0
        hintLabel.textAlignment = .center
        hintLabel.textColor = UIColor(red: 100/255, green: 116/255, blue: 139/255, alpha: 1)
        hintLabel.font = .systemFont(ofSize: 14)
        tableView.backgroundView = hintLabel
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }

    // MARK: - 搜索

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        query = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        rebuildItems()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            query = ""
            rebuildItems()
        }
    }

    private func rebuildItems() {
        items.removeAll()
        guard !query.isEmpty else {
            tableView.backgroundView = hintLabel
            tableView.reloadData()
            return
        }
        for site in Sites.all {
            guard let searchURL = site.searchURL, !searchURL.isEmpty else { continue }
            items.append(SearchItem(title: "在 \(site.name) 搜索「\(query)」",
                                    subtitle: site.note,
                                    site: site,
                                    searchQuery: query))
        }
        if !items.isEmpty {
            let bingQuery = Self.bingAggregateQuery(query)
            let encodedQuery = bingQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let bingURL = "https://www.bing.com/search?q=" + encodedQuery
            let bingSite = Site(name: "必应聚合搜索", note: "一次搜遍全部论坛", url: bingURL, searchURL: nil)
            items.append(SearchItem(title: "必应聚合：一次搜全部论坛",
                                    subtitle: "站内搜索不可用时用这个兜底",
                                    site: bingSite,
                                    searchQuery: nil))
        }
        tableView.backgroundView = items.isEmpty ? hintLabel : nil
        tableView.reloadData()
    }

    private static func bingAggregateQuery(_ q: String) -> String {
        let domains = Sites.all.compactMap { site -> String? in
            guard let host = URL(string: site.url)?.host, !host.isEmpty else { return nil }
            return "site:\(host)"
        }
        return "(" + domains.joined(separator: " OR ") + ") " + q
    }

    // MARK: - 表格

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        let item = items[indexPath.row]
        cell.configure(title: item.title, subtitle: item.subtitle)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        let vc: WebViewController
        if let q = item.searchQuery {
            vc = WebViewController(site: item.site, searchQuery: q)
        } else {
            vc = WebViewController(site: item.site)
        }
        navigationController?.pushViewController(vc, animated: true)
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

        container.backgroundColor = UIColor(red: 18/255, green: 30/255, blue: 53/255, alpha: 1)
        container.layer.cornerRadius = 14
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor(red: 30/255, green: 47/255, blue: 76/255, alpha: 1).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.font = .systemFont(ofSize: 11, weight: .regular)
        subtitleLabel.textColor = UIColor(red: 100/255, green: 116/255, blue: 139/255, alpha: 1)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

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
