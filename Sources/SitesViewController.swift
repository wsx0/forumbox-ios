import UIKit

final class SitesViewController: UITableViewController {

    private lazy var searchButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "搜索 7 个论坛"
        config.image = UIImage(systemName: "sparkles")
        config.imagePadding = 8
        config.baseForegroundColor = Theme.textDim
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.rounded(14.5, .semibold)
            return out
        }
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.backgroundColor = Theme.card
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = Theme.cardBorder.cgColor
        button.addTarget(self, action: #selector(openSearch), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "论坛盒子"
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 82
        tableView.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 24, right: 0)
        tableView.register(CardCell.self, forCellReuseIdentifier: "CardCell")
        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.prefersLargeTitles = false
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)
        setupSearchHeader()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
    }

    private func setupSearchHeader() {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 66))
        header.backgroundColor = .clear
        searchButton.frame = CGRect(x: 16, y: 10, width: header.bounds.width - 32, height: 46)
        searchButton.autoresizingMask = [.flexibleWidth]
        header.addSubview(searchButton)
        tableView.tableHeaderView = header
    }

    @objc private func openSearch() {
        navigationController?.pushViewController(SearchViewController(style: .plain), animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Sites.all.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let site = Sites.all[indexPath.row]
        return tableView.dequeueCard(for: indexPath, model: CardCell.Model(
            emoji: site.emoji,
            title: site.name,
            subtitle: site.note,
            detail: Self.displayURL(site.url),
            showsChevron: true))
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let site = Sites.all[indexPath.row]
        navigationController?.pushViewController(WebViewController(site: site), animated: true)
    }

    private static func displayURL(_ url: String) -> String {
        var text = url
        if text.hasPrefix("https://") { text = String(text.dropFirst(8)) }
        if text.hasPrefix("http://") { text = String(text.dropFirst(7)) }
        return text
    }
}
