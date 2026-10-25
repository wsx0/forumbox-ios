import UIKit

/// 设置 → 视频站点管理
final class VideoSitesViewController: UITableViewController, ScrollToTopable {

    private var sites: [VideoSite] = []
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "视频站点"
        navigationItem.title = "视频站点"
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Theme.cardBorder
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 16)
        tableView.rowHeight = 68 * AppSettings.shared.fontScale
        tableView.sectionHeaderTopPadding = 4
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.register(SiteRowCell.self, forCellReuseIdentifier: SiteRowCell.reuseID)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                           target: self,
                                                           action: #selector(addSite))

        let background = Theme.makeBackgroundView(tableView.bounds)
        tableView.backgroundView = background
        emptyLabel.text = "还没有视频站点\n点右上角 + 添加"
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = Theme.textDim
        emptyLabel.font = Theme.font(13, .regular)
        emptyLabel.frame = background.bounds
        emptyLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        background.addSubview(emptyLabel)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        reload()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
        if let background = tableView.backgroundView {
            emptyLabel.frame = background.bounds
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    func scrollToTop() {
        let top = -tableView.adjustedContentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: top), animated: true)
    }

    private func reload() {
        sites = VideoSiteStore.shared.sites
        tableView.reloadData()
        emptyLabel.isHidden = !sites.isEmpty
    }

    @objc private func addSite() {
        presentEditor(existing: nil)
    }

    private func presentEditor(existing: VideoSite?) {
        let alert = UIAlertController(title: existing == nil ? "添加视频站点" : "编辑视频站点",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "名称"
            field.text = existing?.name
        }
        alert.addTextField { field in
            field.placeholder = "网址（https:// 可省略）"
            field.text = existing?.url
            field.keyboardType = .URL
            field.autocapitalizationType = .none
            field.autocorrectionType = .no
        }
        alert.addTextField { field in
            field.placeholder = "备注（可空，默认显示域名）"
            field.text = existing?.note
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let fields = alert?.textFields,
                  let name = fields.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !name.isEmpty else { return }
            var urlText = fields.count > 1 ? (fields[1].text ?? "") : ""
            urlText = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !urlText.isEmpty else {
                self.presentNoticeAfterDismiss("网址不能为空")
                return
            }
            if !urlText.lowercased().hasPrefix("http://") && !urlText.lowercased().hasPrefix("https://") {
                urlText = "https://" + urlText
            }
            guard let url = URL(string: urlText),
                  let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else {
                self.presentNoticeAfterDismiss("网址格式不正确")
                return
            }
            var note = fields.count > 2 ? (fields[2].text ?? "") : ""
            note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            if note.isEmpty {
                note = url.host ?? urlText
            }
            if let existing = existing {
                VideoSiteStore.shared.update(id: existing.id,
                                             name: name,
                                             note: note,
                                             url: urlText,
                                             emoji: existing.emoji)
            } else {
                VideoSiteStore.shared.add(name: name, note: note, url: urlText)
            }
            self.reload()
        })
        present(alert, animated: true)
    }

    private func confirmDelete(_ site: VideoSite) {
        let alert = UIAlertController(title: "删除站点「\(site.name)」？",
                                      message: "删除后视频 Tab 不再显示这个站点。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            VideoSiteStore.shared.remove(id: site.id)
            self?.reload()
        })
        present(alert, animated: true)
    }

    private func presentNoticeAfterDismiss(_ text: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.presentNotice(text)
        }
    }

    private func presentNotice(_ text: String) {
        let alert = UIAlertController(title: "提示", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sites.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 68 * AppSettings.shared.fontScale
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let site = sites[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: SiteRowCell.reuseID,
                                                 for: indexPath) as! SiteRowCell
        cell.configure(emoji: site.emoji,
                       title: site.name,
                       subtitle: site.note,
                       preferEmoji: true)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < sites.count else { return }
        presentEditor(existing: sites[indexPath.row])
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < sites.count else { return nil }
        let site = sites[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            self?.confirmDelete(site)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
