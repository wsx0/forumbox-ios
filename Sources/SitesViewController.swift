import UIKit

/// 论坛页：站点列表 + 搜索 + 站点管理
final class SitesViewController: UITableViewController {

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

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "论坛"
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

    // MARK: - 导航动作

    @objc private func openSearch() {
        navigationController?.pushViewController(SearchViewController(), animated: true)
    }

    @objc private func addSite() {
        presentEditor(for: nil, at: nil)
    }

    @objc private func showThemePicker() {
        ThemePicker.present(from: self, sourceItem: themeButton)
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

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

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
        guard indexPath.row < Sites.all.count else { return }
        let site = Sites.all[indexPath.row]
        Haptics.tap()
        navigationController?.pushViewController(WebViewController(site: site), animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < Sites.all.count else { return nil }
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

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, indexPath.row < Sites.all.count else { return }
        SiteStore.shared.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView,
                            moveRowAt sourceIndexPath: IndexPath,
                            to destinationIndexPath: IndexPath) {
        SiteStore.shared.move(from: sourceIndexPath.row, to: destinationIndexPath.row)
    }

    private static func displayURL(_ url: String) -> String {
        var text = url
        if text.hasPrefix("https://") { text = String(text.dropFirst(8)) }
        if text.hasPrefix("http://") { text = String(text.dropFirst(7)) }
        return text
    }
}
