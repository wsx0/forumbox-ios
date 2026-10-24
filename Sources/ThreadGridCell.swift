import UIKit

/// 网格卡片（精华 / 搜索共用）：大缩略图 + 标题 + 站点
final class ThreadGridCell: UICollectionViewCell {

    static let reuseID = "ThreadGridCell"

    private let imageContainer = UIView()
    private let imageView = UIImageView()
    private let emojiLabel = UILabel()
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

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.addSubview(imageView)

        emojiLabel.font = .systemFont(ofSize: 34)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.addSubview(emojiLabel)

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
            imageContainer.heightAnchor.constraint(equalToConstant: 118),

            imageView.topAnchor.constraint(equalTo: imageContainer.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainer.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: imageContainer.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainer.trailingAnchor),

            emojiLabel.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

            siteLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            siteLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            siteLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -10),
            siteLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -9)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            imageView.isHidden = false
            emojiLabel.isHidden = true
            imageView.image = nil
            imageTask = ImageLoader.shared.load(thumbURL, referer: entry.site.url) { [weak self] image in
                guard let self = self, self.loadToken == token else { return }
                if let image = image {
                    self.imageView.image = image
                } else {
                    self.imageView.isHidden = true
                    self.emojiLabel.isHidden = false
                }
            }
        } else {
            imageView.isHidden = true
            emojiLabel.isHidden = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadToken += 1
        imageTask?.cancel()
        imageTask = nil
        imageView.image = nil
        imageView.isHidden = true
        emojiLabel.isHidden = false
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
