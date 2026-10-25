import UIKit

/// 论坛页：站点列表 + 一键签到 / 115 入口 + 站点管理
final class SitesViewController: UITableViewController {

    private lazy var themeButton = ThemePicker.makeButton(target: self, action: #selector(showThemePicker))

    private lazy var addButton = UIBarButtonItem(barButtonSystemItem: .add,
                                                 target: self,
                                                 action: #selector(addSite))

    private lazy var signButton = makeActionButton(title: "一键签到", icon: "checkmark.seal")
    private lazy var cloudButton = makeActionButton(title: "115 网盘", icon: "cloud")
    private let headerHint = UILabel()
    private var signRunner: SignInRunner?

    deinit {
        signRunner = nil
    }

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

        signButton.addTarget(self, action: #selector(startSignIn), for: .touchUpInside)
        cloudButton.addTarget(self, action: #selector(openCloud115), for: .touchUpInside)
        setupHeader()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateHeaderHint()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
        if let header = tableView.tableHeaderView, header.frame.width != tableView.bounds.width {
            header.frame.size.width = tableView.bounds.width
            tableView.tableHeaderView = header
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    // MARK: - 头部

    private func makeActionButton(title: String, icon: String) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: icon)
        config.imagePadding = 6
        config.baseForegroundColor = Theme.accent
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = Theme.rounded(13, .semibold)
            return out
        }
        button.configuration = config
        button.backgroundColor = Theme.card
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = Theme.cardBorder.cgColor
        return button
    }

    private func setupHeader() {
        let width = max(tableView.bounds.width, view.bounds.width)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 84))
        header.backgroundColor = .clear

        let stack = UIStackView(arrangedSubviews: [signButton, cloudButton])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stack)

        headerHint.font = .systemFont(ofSize: 11, weight: .medium)
        headerHint.textColor = Theme.textFaint
        headerHint.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerHint)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
            stack.heightAnchor.constraint(equalToConstant: 40),

            headerHint.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 6),
            headerHint.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 18),
            headerHint.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -16)
        ])

        tableView.tableHeaderView = header
        updateHeaderHint()
    }

    private func updateHeaderHint() {
        let signCount = Sites.all.filter { $0.signURL != nil }.count
        headerHint.text = "\(Sites.all.count) 个论坛 · 可签到 \(signCount) 个 · 长按站点可签到 / 编辑"
    }

    // MARK: - 动作

    @objc private func addSite() {
        presentEditor(for: nil, at: nil)
    }

    @objc private func showThemePicker() {
        ThemePicker.present(from: self, sourceItem: themeButton)
    }

    @objc private func startSignIn() {
        runSignIn(with: Sites.all.filter { $0.signURL != nil })
    }

    @objc private func openCloud115() {
        Haptics.tap()
        navigationController?.pushViewController(
            WebViewController(title: "115 网盘", urlString: "https://115.com/"),
            animated: true)
    }

    private func runSignIn(with sites: [Site]) {
        guard signRunner == nil else { return }
        guard !sites.isEmpty else {
            presentNotice("还没有配置签到页的论坛\n长按站点 → 编辑，填写「签到页地址」")
            return
        }
        Haptics.tap()
        setSignRunning(true, message: "签到中…")
        let runner = SignInRunner()
        signRunner = runner
        runner.run(sites: sites) { [weak self] results in
            guard let self = self else { return }
            self.signRunner = nil
            self.setSignRunning(false, message: "一键签到")
            self.showSignResults(results)
        }
    }

    private func setSignRunning(_ running: Bool, message: String) {
        signButton.isEnabled = !running
        signButton.configuration?.showsActivityIndicator = running
        signButton.configuration?.title = message
    }

    private func showSignResults(_ results: [SignResult]) {
        let lines = results.map { "\($0.site.emoji) \($0.site.name)：\($0.status)" }
        let alert = UIAlertController(title: "签到结果",
                                      message: lines.joined(separator: "\n"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }

    // MARK: - 站点增删改

    private func presentEditor(for site: Site?, at index: Int?) {
        let alert = UIAlertController(title: site == nil ? "添加论坛" : "编辑论坛",
                                      message: nil,
                                      preferredStyle: .alert)
        let placeholders = ["名称（必填）", "网址（必填，http/https）", "备注（可空）",
                            "Emoji（可空）", "签到页地址（可空）"]
        let values: [String?] = [site?.name, site?.url, site?.note, site?.emoji, site?.signURL]
        for i in 0..<5 {
            alert.addTextField { field in
                field.placeholder = placeholders[i]
                field.text = values[i]
                field.clearButtonMode = .whileEditing
                if i == 1 || i == 4 {
                    field.keyboardType = .URL
                    field.autocapitalizationType = .none
                    field.autocorrectionType = .no
                }
            }
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self, weak alert] _ in
            guard let self = self, let fields = alert?.textFields, fields.count == 5 else { return }
            let name = (fields[0].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let url = (fields[1].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let note = (fields[2].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let emoji = (fields[3].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let sign = (fields[4].text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

            let lower = url.lowercased()
            guard !name.isEmpty, lower.hasPrefix("http://") || lower.hasPrefix("https://") else {
                self.presentNotice("名称和网址必填，网址需要以 http:// 或 https:// 开头")
                return
            }
            if !sign.isEmpty {
                let lowerSign = sign.lowercased()
                guard lowerSign.hasPrefix("http://") || lowerSign.hasPrefix("https://") else {
                    self.presentNotice("签到页地址需要以 http:// 或 https:// 开头，或留空")
                    return
                }
            }
            let newSite = Site(name: name,
                               note: note,
                               url: url,
                               signURL: sign.isEmpty ? nil : sign,
                               emoji: emoji.isEmpty ? "🌐" : emoji)
            if let index = index {
                SiteStore.shared.replace(at: index, with: newSite)
            } else {
                SiteStore.shared.add(newSite)
            }
            self.tableView.reloadData()
            self.updateHeaderHint()
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
            self?.updateHeaderHint()
            completion(true)
        })
        present(alert, animated: true)
    }

    // MARK: - 表格

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
        open(Sites.all[indexPath.row])
    }

    private func open(_ site: Site) {
        Haptics.tap()
        navigationController?.pushViewController(WebViewController(site: site), animated: true)
    }

    override func tableView(_ tableView: UITableView,
                            contextMenuConfigurationForRowAt indexPath: IndexPath,
                            point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPath.row < Sites.all.count else { return nil }
        let site = Sites.all[indexPath.row]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let open = UIAction(title: "打开",
                                image: UIImage(systemName: "arrow.up.right.square")) { _ in
                self?.open(site)
            }
            let sign = UIAction(title: "单独签到",
                                image: UIImage(systemName: "checkmark.seal")) { _ in
                self?.runSignIn(with: [site])
            }
            let edit = UIAction(title: "编辑",
                                image: UIImage(systemName: "pencil")) { _ in
                self?.presentEditor(for: site, at: indexPath.row)
            }
            let delete = UIAction(title: "删除",
                                  image: UIImage(systemName: "trash"),
                                  attributes: .destructive) { _ in
                self?.confirmDelete(at: indexPath.row) { _ in }
            }
            return UIMenu(children: [open, sign, edit, delete])
        }
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
        updateHeaderHint()
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
