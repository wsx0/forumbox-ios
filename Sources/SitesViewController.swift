import UIKit

/// 论坛页：站点列表 + 站点管理
final class SitesViewController: UITableViewController {

    private lazy var themeButton = ThemePicker.makeButton(target: self, action: #selector(showThemePicker))

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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
    }

    // MARK: - 导航动作

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
        let placeholders = ["名称（必填）", "网址（必填，http/https）", "备注（可空）", "Emoji（可空）"]
        let values: [String?] = [site?.name, site?.url, site?.note, site?.emoji]
        for i in 0..<4 {
            alert.addTextField { field in
                field.placeholder = placeholders[i]
                field.text = values[i]
                field.clearButtonMode = .whileEditing
                if i == 1 {
                    field.keyboardType = .URL
                    field.autocapitalizationType = .none
                    field.autocorrectionType = .no
                }
            }
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self, weak alert] _ in
            guard let self = self, let fields = alert?.textFields, fields.count == 4 else { return }
            let name = (fields[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let url = (fields[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let note = (fields[2].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let emoji = (fields[3].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            let lower = url.lowercased()
            guard !name.isEmpty, lower.hasPrefix("http://") || lower.hasPrefix("https://") else {
                self.presentNotice("名称和网址必填，网址需要以 http:// 或 https:// 开头")
                return
            }
            let newSite = Site(name: name,
                               note: note,
                               url: url,
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
            detail: site.url.shortURL,
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
}
