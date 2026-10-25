import UIKit

/// 列表通用卡片单元格（收藏夹 / 收藏列表共用）
final class CardCell: UITableViewCell {

    struct Model {
        let emoji: String
        let title: String
        let subtitle: String
        let detail: String?
        let showsChevron: Bool
    }

    private let container = UIView()
    private let emojiBackground = UIView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let detailLabel = UILabel()
    private let chevronLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .default
        selectedBackgroundView = UIView()

        container.backgroundColor = Theme.card
        container.layer.cornerRadius = 16
        container.translatesAutoresizingMaskIntoConstraints = false
        if Theme.palette.isLight && Theme.isPlainStyle {
            container.layer.borderWidth = 0
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOpacity = 0.04
            container.layer.shadowRadius = 3
            container.layer.shadowOffset = CGSize(width: 0, height: 1)
        } else {
            container.layer.borderWidth = 1
            container.layer.borderColor = Theme.cardBorder.cgColor
        }
        contentView.addSubview(container)

        emojiBackground.backgroundColor = Theme.emojiBg
        emojiBackground.layer.cornerRadius = 12
        emojiBackground.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emojiBackground)

        emojiLabel.font = .systemFont(ofSize: 22)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiBackground.addSubview(emojiLabel)

        titleLabel.font = Theme.rounded(16, .semibold)
        titleLabel.textColor = Theme.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = Theme.textDim
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.lineBreakMode = .byTruncatingTail
        subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        detailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        detailLabel.textColor = Theme.textFaint
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.lineBreakMode = .byTruncatingMiddle

        chevronLabel.text = "›"
        chevronLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        chevronLabel.textColor = Theme.textFaint
        chevronLabel.textAlignment = .center
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(detailLabel)
        container.addSubview(chevronLabel)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            emojiBackground.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            emojiBackground.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            emojiBackground.widthAnchor.constraint(equalToConstant: 44),
            emojiBackground.heightAnchor.constraint(equalToConstant: 44),

            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackground.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackground.centerYAnchor),

            chevronLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            chevronLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronLabel.widthAnchor.constraint(equalToConstant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: emojiBackground.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),

            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 3),
            detailLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with model: Model) {
        emojiLabel.text = model.emoji
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
        subtitleLabel.isHidden = model.subtitle.isEmpty
        if let detail = model.detail, !detail.isEmpty {
            detailLabel.text = detail
            detailLabel.isHidden = false
        } else {
            detailLabel.text = nil
            detailLabel.isHidden = true
        }
        chevronLabel.isHidden = !model.showsChevron
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

extension UITableView {
    /// 统一从复用池取出 CardCell 并绑定模型
    func dequeueCard(for indexPath: IndexPath, model: CardCell.Model) -> CardCell {
        let cell = dequeueReusableCell(withIdentifier: "CardCell", for: indexPath) as! CardCell
        cell.configure(with: model)
        return cell
    }
}
