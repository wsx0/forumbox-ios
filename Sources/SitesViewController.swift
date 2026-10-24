import UIKit

final class SitesViewController: UITableViewController {

    private enum DigestRow {
        case loading
        case item(ThreadItem, Site)
        case more(Int)
        case empty
    }

    private let digestAggregator = SiteFetchAggregator()
    private var digestResults: [SiteThreadResult] = []
    private var isDigesting = false
    private var hasLoadedDigest = false

    private lazy var searchButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "搜索全部论坛"
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

    private lazy var themeButton = UIBarButtonItem(image: UIImage(systemName: "paintpalette"),
                                                   style: .plain,
                                                   target: self,
                                                   action: #selector(showThemePicker))

    private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add,
                                                 target: self,
                                                 action: #selector(addSite))

    private var digestRows: [DigestRow] {
        if digestResults.isEmpty {
            return [isDigesting ? .loading : .empty]
        }
        var rows: [DigestRow] = []
        var total = 0
        for result in digestResults {
            total += result.items.count
            for item in result.items.prefix(2) {
                rows.append(.item(item, result.site))
            }
        }
        if rows.isEmpty {
            return [isDigesting ? .loading : .empty]
        }
        rows.append(.more(total))
        return rows
    }

    deinit {
        digestAggregator.cancel()
    }

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
        navigationItem.leftBarButtonItem = themeButton
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
        navigationController?.navigationBar.prefersLargeTitles = false
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)
        setupSearchHeader()
        setupRefreshControl()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasLoadedDigest {
            hasLoadedDigest = true
            loadDigest()
        }
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

    private func setupRefreshControl() {
        let refresh = UIRefreshControl()
        refresh.tintColor = Theme.accent
        refresh.addTarget(self, action: #selector(refreshDigest), for: .valueChanged)
        tableView.refreshControl = refresh
    }

    // MARK: - 精华抓取

    @objc private func refreshDigest() {
        digestAggregator.cancel()
        isDigesting = false
        loadDigest()
    }

    private func loadDigest() {
        let digestSites = Sites.all.filter { $0.digestURL != nil }
        guard !digestSites.isEmpty else {
            digestResults = []
            tableView.refreshControl?.endRefreshing()
            tableView.reloadData()
            return
        }
        isDigesting = true
        digestResults = digestSites.map { SiteThreadResult(site: $0, status: "抓取中…", items: []) }
        tableView.reloadData()
        digestAggregator.start(sites: digestSites,
                               needsAutoSearch: false,
                               urlForSite: { $0.digestURL },
                               update: { [weak self] result in
                                guard let self = self else { return }
                                if let index = self.digestResults.firstIndex(where: { $0.site.name == result.site.name }) {
                                    self.digestResults[index] = result
                                    self.tableView.reloadData()
                                }
                               },
                               finished: { [weak self] in
                                guard let self = self else { return }
                                self.isDigesting = false
                                self.tableView.refreshControl?.endRefreshing()
                                self.tableView.reloadData()
                               })
    }

    private func refreshDigestAfterSiteChange() {
        digestAggregator.cancel()
        isDigesting = false
        loadDigest()
    }

    // MARK: - 导航动作

    @objc private func openSearch() {
        navigationController?.pushViewController(SearchViewController(style: .plain), animated: true)
    }

    @objc private func addSite() {
        presentEditor(for: nil, at: nil)
    }

    // MARK: - 主题切换

    @objc private func showThemePicker() {
        let sheet = UIAlertController(title: "选择主题", message: nil, preferredStyle: .actionSheet)
        for style in ThemeManager.Style.allCases {
            let isCurrent = ThemeManager.shared.style == style
            let title = isCurrent ? "\(style.displayName)  ✓" : style.displayName
            sheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applyTheme(style)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = themeButton
        }
        present(sheet, animated: true)
    }

    private func applyTheme(_ style: ThemeManager.Style) {
        ThemeManager.shared.setStyle(style)
        Theme.applyAppearance()
        guard let window = view.window else { return }
        let root = SitesViewController(style: .plain)
        let nav = UINavigationController(rootViewController: root)
        window.rootViewController = nav
        window.tintColor = Theme.accent
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }

    // MARK: - 站点增删改

    private func presentEditor(for site: Site?, at index: Int?) {
        let alert = UIAlertController(title: site == nil ? "添加论坛" : "编辑论坛",
                                      message: nil,
                                      preferredStyle: .alert)
        let placeholders = ["名称（必填）", "网址（必填，http/https）", "备注（可空）",
                            "Emoji（可空）", "搜索页地址（可空）", "精华页地址（可空）"]
        let values: [String?] = [site?.name, site?.url, site?.note, site?.emoji,
                                 site?.searchURL, site?.digestURL]
        for i in 0..<6 {
            alert.addTextField { field in
                field.placeholder = placeholders[i]
                field.text = values[i]
                field.clearButtonMode = .whileEditing
                if i == 1 || i == 4 || i == 5 {
                    field.keyboardType = .URL
                    field.autocapitalizationType = .none
                    field.autocorrectionType = .no
                }
            }
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self, weak alert] _ in
            guard let self = self, let fields = alert?.textFields, fields.count == 6 else { return }
            let name = (fields[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let url = (fields[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let note = (fields[2].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let emoji = (fields[3].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let search = (fields[4].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let digest = (fields[5].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            let lower = url.lowercased()
            guard !name.isEmpty, lower.hasPrefix("http://") || lower.hasPrefix("https://") else {
                self.presentNotice("名称和网址必填，网址需要以 http:// 或 https:// 开头")
                return
            }
            for extra in [search, digest] where !extra.isEmpty {
                let lowerExtra = extra.lowercased()
                guard lowerExtra.hasPrefix("http://") || lowerExtra.hasPrefix("https://") else {
                    self.presentNotice("搜索页 / 精华页地址需要以 http:// 或 https:// 开头，或留空")
                    return
                }
            }
            let newSite = Site(name: name,
                               note: note,
                               url: url,
                               searchURL: search.isEmpty ? nil : search,
                               digestURL: digest.isEmpty ? nil : digest,
                               emoji: emoji.isEmpty ? "🌐" : emoji)
            if let index = index {
                SiteStore.shared.replace(at: index, with: newSite)
            } else {
                SiteStore.shared.add(newSite)
            }
            self.tableView.reloadData()
            self.refreshDigestAfterSiteChange()
        })
        present(alert, animated: true)
    }

    private func confirmDelete(at index: Int, completion: @escaping (Bool) -> Void) {
        guard Sites.all.indices.contains(index) else {
            completion(false)
            return
        }
        let site = Sites.all[index]
        let alert = UIAlertController(title: "删除「\(site.name)」？",
                                      message: "删除后还可以重新添加。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in completion(false) })
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            SiteStore.shared.remove(at: index)
            self?.tableView.reloadData()
            self?.refreshDigestAfterSiteChange()
            completion(true)
        })
        present(alert, animated: true)
    }

    private func presentNotice(_ text: String) {
        let alert = UIAlertController(title: "提示", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }

    // MARK: - 表格

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return digestRows.count
        }
        return Sites.all.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView()
        header.backgroundColor = .clear
        let label = UILabel()
        label.font = Theme.rounded(12, .semibold)
        label.textColor = Theme.textFaint
        label.translatesAutoresizingMaskIntoConstraints = false
        if section == 0 {
            label.text = "✦ 精华速览 · 全部论坛"
        } else {
            label.text = "📚 论坛（\(Sites.all.count)）"
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
        return 34
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let rows = digestRows
            guard indexPath.row < rows.count else {
                return tableView.dequeueCard(for: indexPath, model: CardCell.Model(
                    emoji: "🍃", title: "暂时没抓到精华", subtitle: "下拉刷新试试",
                    detail: nil, showsChevron: false))
            }
            switch rows[indexPath.row] {
            case .loading:
                return tableView.dequeueCard(for: indexPath, model: CardCell.Model(
                    emoji: "⏳", title: "正在抓取各论坛精华…", subtitle: "首次加载需要十几秒",
                    detail: nil, showsChevron: false))
            case .item(let item, let site):
                return tableView.dequeueCard(for: indexPath, model: CardCell.Model(
                    emoji: site.emoji, title: item.title, subtitle: site.name,
                    detail: nil, showsChevron: true))
            case .more(let count):
                return tableView.dequeueCard(for: indexPath, model: CardCell.Model(
                    emoji: "✨", title: "查看全部精华", subtitle: "共 \(count) 条",
                    detail: nil, showsChevron: true))
            case .empty:
                return tableView.dequeueCard(for: indexPath, model: CardCell.Model(
                    emoji: "🍃", title: "暂时没抓到精华", subtitle: "下拉刷新试试",
                    detail: nil, showsChevron: false))
            }
        }
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
        if indexPath.section == 0 {
            let rows = digestRows
            guard indexPath.row < rows.count else { return }
            switch rows[indexPath.row] {
            case .item(let item, let site):
                navigationController?.pushViewController(
                    WebViewController(title: site.name, urlString: item.url),
                    animated: true)
            case .more:
                navigationController?.pushViewController(DigestViewController(style: .plain), animated: true)
            case .loading, .empty:
                break
            }
            return
        }
        guard indexPath.row < Sites.all.count else { return }
        let site = Sites.all[indexPath.row]
        navigationController?.pushViewController(WebViewController(site: site), animated: true)
    }

    // MARK: - 站点编辑（仅第 1 个 section 可编辑）

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return indexPath.section == 1 ? .delete : .none
    }

    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                            toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        guard proposedDestinationIndexPath.section == 1 else {
            return IndexPath(row: max(Sites.all.count - 1, 0), section: 1)
        }
        return proposedDestinationIndexPath
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard indexPath.section == 1, editingStyle == .delete, indexPath.row < Sites.all.count else { return }
        SiteStore.shared.remove(at: indexPath.row)
        tableView.reloadData()
        refreshDigestAfterSiteChange()
    }

    override func tableView(_ tableView: UITableView,
                            moveRowAt sourceIndexPath: IndexPath,
                            to destinationIndexPath: IndexPath) {
        guard sourceIndexPath.section == 1, destinationIndexPath.section == 1 else { return }
        SiteStore.shared.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
        refreshDigestAfterSiteChange()
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 1, indexPath.row < Sites.all.count else { return nil }
        let site = Sites.all[indexPath.row]
        let edit = UIContextualAction(style: .normal, title: "编辑") { [weak self] _, _, completion in
            self?.presentEditor(for: site, at: indexPath.row)
            completion(true)
        }
        edit.backgroundColor = Theme.accent
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            self?.confirmDelete(at: indexPath.row, completion: completion)
        }
        return UISwipeActionsConfiguration(actions: [delete, edit])
    }

    private static func displayURL(_ url: String) -> String {
        var text = url
        if text.hasPrefix("https://") { text = String(text.dropFirst(8)) }
        if text.hasPrefix("http://") { text = String(text.dropFirst(7)) }
        return text
    }
}
