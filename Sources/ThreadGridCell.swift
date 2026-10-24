import UIKit

/// 网格卡片（精华 / 搜索共用）：缩略图 + 标题 + 站点
final class ThreadGridCell: UICollectionViewCell {

    static let reuseID = "ThreadGridCell"

    private let imageContainer = UIView()
    private let placeholderGradient = CAGradientLayer()
    private let imageView = UIImageView()
    private let emojiLabel = UILabel()
    private let noCoverLabel = UILabel()
    private let titleLabel = UILabel()
    private let siteLabel = UILabel()

    private var loadToken = 0
    private var imageTask: URLSessionDataTask?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = Theme.card
        contentView.layer.cornerRadius = Design.cardCorner
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = Theme.cardBorder.cgColor
        contentView.layer.masksToBounds = true

        imageContainer.backgroundColor = Theme.emojiBg
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageContainer)

        placeholderGradient.colors = [Theme.accentSoft.withAlphaComponent(0.30).cgColor,
                                      Theme.accent.withAlphaComponent(0.14).cgColor]
        placeholderGradient.startPoint = CGPoint(x: 0, y: 0)
        placeholderGradient.endPoint = CGPoint(x: 1, y: 1)
        imageContainer.layer.insertSublayer(placeholderGradient, at: 0)

        emojiLabel.font = .systemFont(ofSize: 38)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.addSubview(emojiLabel)

        noCoverLabel.text = "暂无封面"
        noCoverLabel.font = .systemFont(ofSize: 9.5, weight: .medium)
        noCoverLabel.textColor = Theme.textFaint
        noCoverLabel.textAlignment = .center
        noCoverLabel.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.addSubview(noCoverLabel)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.addSubview(imageView)

        titleLabel.font = Theme.rounded(14, .semibold)
        titleLabel.textColor = Theme.text
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        siteLabel.font = .systemFont(ofSize: 10, weight: .medium)
        siteLabel.textColor = Theme.textFaint
        siteLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(siteLabel)

        NSLayoutConstraint.activate([
            imageContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageContainer.heightAnchor.constraint(equalToConstant: 108),

            emojiLabel.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor, constant: -8),

            noCoverLabel.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            noCoverLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 2),

            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

            siteLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            siteLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -10),
            siteLabel.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 4),
            siteLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        placeholderGradient.frame = imageContainer.bounds
    }

    func configure(entry: FeedEntry) {
        loadToken += 1
        let token = loadToken

        titleLabel.text = entry.item.title
        siteLabel.text = "\(entry.site.emoji) \(entry.site.name)"
        emojiLabel.text = entry.site.emoji

        imageTask?.cancel()
        imageTask = nil

        if let thumbURL = entry.item.thumbURL, !thumbURL.isEmpty {
            showPlaceholder(false)
            imageTask = ImageLoader.shared.load(thumbURL, referer: entry.site.url) { [weak self] image in
                guard let self = self, self.loadToken == token else { return }
                if let image = image {
                    self.imageView.image = image
                    self.imageView.isHidden = false
                } else {
                    self.showPlaceholder(true)
                }
            }
        } else {
            showPlaceholder(true)
        }
    }

    private func showPlaceholder(_ show: Bool) {
        if show {
            imageView.image = nil
            imageView.isHidden = true
        }
        emojiLabel.isHidden = !show
        noCoverLabel.isHidden = !show
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadToken += 1
        imageTask?.cancel()
        imageTask = nil
        imageView.image = nil
        imageView.isHidden = true
        emojiLabel.isHidden = false
        noCoverLabel.isHidden = false
        contentView.transform = .identity
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.contentView.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.97, y: 0.97)
                    : .identity
            }
        }
    }
}
