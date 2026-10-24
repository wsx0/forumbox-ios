import UIKit

/// 精华 / 搜索结果用的紧凑帖子行
final class ThreadCell: UITableViewCell {

    private let container = UIView()
    private let emojiBackground = UIView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let chevronLabel = UILabel()

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

        emojiBackground.backgroundColor = Theme.emojiBg
        emojiBackground.layer.cornerRadius = 8
        emojiBackground.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emojiBackground)

        emojiLabel.font = .systemFont(ofSize: 16)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiBackground.addSubview(emojiLabel)

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

            emojiBackground.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            emojiBackground.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            emojiBackground.widthAnchor.constraint(equalToConstant: 30),
            emojiBackground.heightAnchor.constraint(equalToConstant: 30),

            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackground.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackground.centerYAnchor),

            chevronLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            chevronLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronLabel.widthAnchor.constraint(equalToConstant: 10),

            titleLabel.leadingAnchor.constraint(equalTo: emojiBackground.trailingAnchor, constant: 10),
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

    func configure(emoji: String, title: String, meta: String) {
        emojiLabel.text = emoji
        titleLabel.text = title
        metaLabel.text = meta
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
