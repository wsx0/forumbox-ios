import UIKit

/// 收藏 / 长标题的分组行：两行标题 + 一行说明
final class FavoriteRowCell: UITableViewCell {

    static let reuseID = "FavoriteRowCell"

    private let emojiBackground = UIView()
    private let emojiLabel = UILabel()
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

        emojiBackground.backgroundColor = Theme.emojiBg
        emojiBackground.layer.cornerRadius = 12
        emojiBackground.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emojiBackground)

        emojiLabel.font = .systemFont(ofSize: 22)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiBackground.addSubview(emojiLabel)

        titleLabel.font = Theme.rounded(15, .medium)
        titleLabel.textColor = Theme.text
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        metaLabel.font = .systemFont(ofSize: 13, weight: .regular)
        metaLabel.textColor = Theme.textDim
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        metaLabel.lineBreakMode = .byTruncatingTail

        chevronLabel.text = "›"
        chevronLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        chevronLabel.textColor = Theme.textFaint
        chevronLabel.textAlignment = .center
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(metaLabel)
        contentView.addSubview(chevronLabel)

        NSLayoutConstraint.activate([
            emojiBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            emojiBackground.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            emojiBackground.widthAnchor.constraint(equalToConstant: 44),
            emojiBackground.heightAnchor.constraint(equalToConstant: 44),

            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackground.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackground.centerYAnchor),

            chevronLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronLabel.widthAnchor.constraint(equalToConstant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: emojiBackground.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),

            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            metaLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),
            metaLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(emoji: String, title: String, meta: String) {
        if Theme.isPlainStyle {
            emojiLabel.text = title.identityInitial
            emojiLabel.font = Theme.rounded(17, .semibold)
            emojiLabel.textColor = Theme.textDim
            emojiBackground.backgroundColor = Theme.tonal
        } else {
            emojiLabel.text = emoji
            emojiLabel.font = .systemFont(ofSize: 22)
            emojiLabel.textColor = Theme.text
            emojiBackground.backgroundColor = Theme.emojiBg
        }
        titleLabel.text = title
        metaLabel.text = meta
    }
}
