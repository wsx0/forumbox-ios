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
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 124, bottom: 0, right: 16)
        tableView.rowHeight = 86 * AppSettings.shared.fontScale
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
        return 86 * AppSettings.shared.fontScale
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

/// 视频收藏行：缩略图 + 真实标题 + 域名/时间
final class VideoFavoriteRowCell: UITableViewCell {

    static let reuseID = "VideoFavoriteRowCell"
    private static let imageCache = NSCache<NSString, UIImage>()

    private let thumbBackground = UIView()
    private let thumbView = UIImageView()
    private let fallbackIcon = UIImageView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let chevronLabel = UILabel()
    private var task: URLSessionDataTask?
    private var currentThumbURL: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = Theme.card
        contentView.backgroundColor = Theme.card
        selectionStyle = .default
        let selected = UIView()
        selected.backgroundColor = Theme.tonal
        selectedBackgroundView = selected

        thumbBackground.backgroundColor = Theme.tonal
        thumbBackground.layer.cornerRadius = 8
        thumbBackground.clipsToBounds = true
        thumbBackground.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbBackground)

        thumbView.contentMode = .scaleAspectFill
        thumbView.clipsToBounds = true
        thumbView.isHidden = true
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        thumbBackground.addSubview(thumbView)

        fallbackIcon.image = UIImage(systemName: "play.rectangle.fill")
        fallbackIcon.tintColor = Theme.accent
        fallbackIcon.contentMode = .scaleAspectFit
        fallbackIcon.translatesAutoresizingMaskIntoConstraints = false
        thumbBackground.addSubview(fallbackIcon)

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
            thumbBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbBackground.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            thumbBackground.widthAnchor.constraint(equalToConstant: 96),
            thumbBackground.heightAnchor.constraint(equalToConstant: 54),

            thumbView.topAnchor.constraint(equalTo: thumbBackground.topAnchor),
            thumbView.leadingAnchor.constraint(equalTo: thumbBackground.leadingAnchor),
            thumbView.trailingAnchor.constraint(equalTo: thumbBackground.trailingAnchor),
            thumbView.bottomAnchor.constraint(equalTo: thumbBackground.bottomAnchor),

            fallbackIcon.centerXAnchor.constraint(equalTo: thumbBackground.centerXAnchor),
            fallbackIcon.centerYAnchor.constraint(equalTo: thumbBackground.centerYAnchor),
            fallbackIcon.widthAnchor.constraint(equalToConstant: 24),
            fallbackIcon.heightAnchor.constraint(equalToConstant: 24),

            chevronLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronLabel.widthAnchor.constraint(equalToConstant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: thumbBackground.trailingAnchor, constant: 12),
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

    override func prepareForReuse() {
        super.prepareForReuse()
        task?.cancel()
        task = nil
        currentThumbURL = nil
        showFallback()
    }

    func configure(item: VideoFavorite) {
        titleLabel.text = item.title
        let host = URL(string: item.url)?.host ?? item.url
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        metaLabel.text = "\(host) · \(formatter.string(from: item.createdAt))"

        if let thumb = item.thumbnailURL, !thumb.isEmpty {
            loadThumbnail(thumb)
        } else {
            currentThumbURL = nil
            showFallback()
        }
    }

    private func loadThumbnail(_ urlString: String) {
        currentThumbURL = urlString
        if let cached = Self.imageCache.object(forKey: urlString as NSString) {
            showImage(cached)
            return
        }
        showFallback()
        guard let url = URL(string: urlString) else { return }
        task?.cancel()
        task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            Self.imageCache.setObject(image, forKey: urlString as NSString)
            DispatchQueue.main.async {
                guard let self = self, self.currentThumbURL == urlString else { return }
                self.showImage(image)
            }
        }
        task?.resume()
    }

    private func showImage(_ image: UIImage) {
        thumbView.image = image
        thumbView.isHidden = false
        fallbackIcon.isHidden = true
    }

    private func showFallback() {
        thumbView.image = nil
        thumbView.isHidden = true
        fallbackIcon.isHidden = false
    }
}
