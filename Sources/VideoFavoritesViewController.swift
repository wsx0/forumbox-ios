import UIKit

/// 视频收藏列表
final class VideoFavoritesViewController: UITableViewController, ScrollToTopable {

    private var items: [VideoFavorite] = []
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "视频收藏"
        navigationItem.title = "视频收藏"
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Theme.cardBorder
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 16)
        tableView.rowHeight = 72 * AppSettings.shared.fontScale
        tableView.sectionHeaderTopPadding = 4
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.register(VideoFavoriteRowCell.self,
                           forCellReuseIdentifier: VideoFavoriteRowCell.reuseID)

        let background = Theme.makeBackgroundView(tableView.bounds)
        tableView.backgroundView = background
        emptyLabel.text = "还没有视频收藏\n在播放页点右上角 ☆ 收藏"
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
        items = VideoFavoriteStore.shared.items
        tableView.reloadData()
        emptyLabel.isHidden = !items.isEmpty
        navigationItem.rightBarButtonItem = items.isEmpty
            ? nil
            : UIBarButtonItem(title: "清空", style: .plain, target: self, action: #selector(clearAll))
    }

    @objc private func clearAll() {
        let alert = UIAlertController(title: "清空视频收藏？",
                                      message: "只会清空视频收藏，不影响论坛收藏。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "清空", style: .destructive) { [weak self] _ in
            VideoFavoriteStore.shared.removeAll()
            self?.reload()
        })
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72 * AppSettings.shared.fontScale
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VideoFavoriteRowCell.reuseID,
                                                 for: indexPath) as! VideoFavoriteRowCell
        cell.configure(item: items[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < items.count,
              let url = URL(string: items[indexPath.row].url) else { return }
        VideoOpener.open(url: url,
                         title: items[indexPath.row].title,
                         from: self,
                         navigation: navigationController)
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.row < items.count else { return nil }
        let item = items[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            VideoFavoriteStore.shared.remove(id: item.id)
            self?.reload()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

/// 视频收藏行：播放图标 + 标题 + 域名/时间
final class VideoFavoriteRowCell: UITableViewCell {

    static let reuseID = "VideoFavoriteRowCell"

    private let iconBackground = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let chevronLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = Theme.card
        contentView.backgroundColor = Theme.card
        selectionStyle = .default
        let selected = UIView()
        selected.backgroundColor = Theme.tonal
        selectedBackgroundView = selected

        iconBackground.backgroundColor = Theme.tonal
        iconBackground.layer.cornerRadius = 12
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconBackground)

        iconView.image = UIImage(systemName: "play.rectangle.fill")
        iconView.tintColor = Theme.accent
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(iconView)

        titleLabel.font = Theme.rounded(15, .medium)
        titleLabel.textColor = Theme.text
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        metaLabel.font = Theme.font(13, .regular)
        metaLabel.textColor = Theme.textDim
        metaLabel.lineBreakMode = .byTruncatingTail
        metaLabel.translatesAutoresizingMaskIntoConstraints = false

        chevronLabel.text = "›"
        chevronLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        chevronLabel.textColor = Theme.textFaint
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(metaLabel)
        contentView.addSubview(chevronLabel)

        NSLayoutConstraint.activate([
            iconBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconBackground.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 44),
            iconBackground.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            chevronLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronLabel.widthAnchor.constraint(equalToConstant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),

            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            metaLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),
            metaLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -13)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(item: VideoFavorite) {
        titleLabel.text = item.title
        let host = URL(string: item.url)?.host ?? item.url
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        metaLabel.text = "\(host) · \(formatter.string(from: item.createdAt))"
    }
}
