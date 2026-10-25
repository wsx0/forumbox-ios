import UIKit

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

        task?.cancel()
        task = nil
        if let thumb = item.thumbnailURL, !thumb.isEmpty {
            loadThumbnail(thumb, referer: item.url)
        } else {
            currentThumbURL = nil
            showFallback()
        }
    }

    private func loadThumbnail(_ urlString: String, referer: String) {
        currentThumbURL = urlString
        if let cached = Self.imageCache.object(forKey: urlString as NSString) {
            showImage(cached)
            return
        }
        showFallback()
        guard let url = URL(string: urlString) else { return }
        task?.cancel()
        var request = URLRequest(url: url)
        request.setValue(referer, forHTTPHeaderField: "Referer")
        request.setValue(UserAgents.mobileSafari, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        task = URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
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
