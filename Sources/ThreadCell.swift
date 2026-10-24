import UIKit

/// 精华 / 搜索结果用的紧凑帖子行（带缩略图，无图时显示 emoji）
final class ThreadCell: UITableViewCell {

    private let container = UIView()
    private let mediaContainer = UIView()
    private let thumbView = UIImageView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let chevronLabel = UILabel()

    private var loadToken = 0

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .default
        selectedBackgroundView = UIView()

        container.backgroundColor = Theme.card
        container.layer.cornerRadius = 12
        container.layer.borderWidth = 1
        container.layer.borderColor = Theme.cardBorder.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        mediaContainer.backgroundColor = Theme.emojiBg
        mediaContainer.layer.cornerRadius = 10
        mediaContainer.layer.masksToBounds = true
        mediaContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mediaContainer)

        thumbView.contentMode = .scaleAspectFill
        thumbView.clipsToBounds = true
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addSubview(thumbView)

        emojiLabel.font = .systemFont(ofSize: 22)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        mediaContainer.addSubview(emojiLabel)

        titleLabel.font = Theme.rounded(14.5, .semibold)
        titleLabel.textColor = Theme.text
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        metaLabel.font = .systemFont(ofSize: 10.5, weight: .medium)
        metaLabel.textColor = Theme.textFaint
        metaLabel.translatesAutoresizingMaskIntoConstraints = false

        chevronLabel.text = "›"
        chevronLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        chevronLabel.textColor = Theme.textFaint
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(metaLabel)
        container.addSubview(chevronLabel)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Design.hPad),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Design.hPad),
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Design.cardSpacing / 2),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Design.cardSpacing / 2),

            mediaContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            mediaContainer.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            mediaContainer.widthAnchor.constraint(equalToConstant: 52),
            mediaContainer.heightAnchor.constraint(equalToConstant: 52),

            thumbView.topAnchor.constraint(equalTo: mediaContainer.topAnchor),
            thumbView.bottomAnchor.constraint(equalTo: mediaContainer.bottomAnchor),
            thumbView.leadingAnchor.constraint(equalTo: mediaContainer.leadingAnchor),
            thumbView.trailingAnchor.constraint(equalTo: mediaContainer.trailingAnchor),

            emojiLabel.centerXAnchor.constraint(equalTo: mediaContainer.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: mediaContainer.centerYAnchor),

            chevronLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            chevronLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronLabel.widthAnchor.constraint(equalToConstant: 10),

            titleLabel.leadingAnchor.constraint(equalTo: mediaContainer.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: chevronLabel.leadingAnchor, constant: -6),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 11),

            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -6),
            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            metaLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -10)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(emoji: String,
                   title: String,
                   meta: String,
                   thumbURL: String?,
                   referer: String?) {
        loadToken += 1
        let token = loadToken

        emojiLabel.text = emoji
        titleLabel.text = title
        metaLabel.text = meta

        if let thumbURL = thumbURL, !thumbURL.isEmpty {
            thumbView.isHidden = false
            emojiLabel.isHidden = true
            thumbView.image = nil
            ImageLoader.shared.load(thumbURL, referer: referer) { [weak self] image in
                guard let self = self, self.loadToken == token else { return }
                if let image = image {
                    self.thumbView.image = image
                } else {
                    self.thumbView.isHidden = true
                    self.emojiLabel.isHidden = false
                }
            }
        } else {
            thumbView.isHidden = true
            emojiLabel.isHidden = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadToken += 1
        thumbView.image = nil
        thumbView.isHidden = true
        emojiLabel.isHidden = false
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        UIView.animate(withDuration: 0.12) {
            self.container.transform = highlighted
                ? CGAffineTransform(scaleX: 0.985, y: 0.985)
                : .identity
        }
    }
}
