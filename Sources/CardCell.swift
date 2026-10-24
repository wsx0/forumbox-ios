import UIKit

/// 列表通用卡片单元格（论坛列表 / 搜索结果 共用）
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
        container.layer.borderWidth = 1
        container.layer.borderColor = Theme.cardBorder.cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(container)

        emojiBackground.backgroundColor = Theme.emojiBg
        emojiBackground.layer.cornerRadius = 11
        emojiBackground.layer.borderWidth = 1
        emojiBackground.layer.borderColor = Theme.cardBorder.cgColor
        emojiBackground.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(emojiBackground)

        emojiLabel.font = .systemFont(ofSize: 21)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiBackground.addSubview(emojiLabel)

        titleLabel.font = Theme.rounded(16)
        titleLabel.textColor = Theme.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.font = .systemFont(ofSize: 10.5, weight: .medium)
        subtitleLabel.textColor = Theme.accent
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        detailLabel.font = .systemFont(ofSize: 10.5, weight: .regular)
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
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            emojiBackground.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 13),
            emojiBackground.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            emojiBackground.widthAnchor.constraint(equalToConstant: 40),
            emojiBackground.heightAnchor.constraint(equalToConstant: 40),

            emojiLabel.centerXAnchor.constraint(equalTo: emojiBackground.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiBackground.centerYAnchor),

            chevronLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            chevronLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            chevronLabel.widthAnchor.constraint(equalToConstant: 12),

            titleLabel.leadingAnchor.constraint(equalTo: emojiBackground.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 13),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            subtitleLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8),

            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            detailLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevronLabel.leadingAnchor, constant: -8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with model: Model) {
        emojiLabel.text = model.emoji
        titleLabel.text = model.title
        subtitleLabel.text = model.subtitle
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
