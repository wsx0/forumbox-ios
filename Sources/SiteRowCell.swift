import UIKit

/// 论坛分组列表的站点行（Material 风格：白底 + 分隔线，无独立卡片）
final class SiteRowCell: UITableViewCell {

    static let reuseID = "SiteRowCell"

    private let emojiBackground = UIView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
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

        titleLabel.font = Theme.rounded(16, .semibold)
        titleLabel.textColor = Theme.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = Theme.textDim
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.lineBreakMode = .byTruncatingTail

        chevronLabel.text = "›"
        chevronLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        chevronLabel.textColor = Theme.textFaint
        chevronLabel.textAlignment = .center
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
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
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 13),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -13)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(site: Site) {
        configure(emoji: site.emoji, title: site.name, subtitle: site.note)
    }

    func configure(emoji: String, title: String, subtitle: String) {
        applyIdentity(emoji: emoji, title: title)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle.isEmpty
    }

    private func applyIdentity(emoji: String, title: String) {
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
    }
}
