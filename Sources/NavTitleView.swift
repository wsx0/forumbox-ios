import UIKit

/// 左对齐的导航标题（主标题 + 副标题），对应参考 App 的 AppTabHeader
final class NavTitleView: UIView {

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stack = UIStackView()

    init(title: String, subtitle: String?) {
        super.init(frame: .zero)

        titleLabel.font = Theme.rounded(20, .bold)
        titleLabel.textColor = Theme.text
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.textColor = Theme.textDim
        subtitleLabel.lineBreakMode = .byTruncatingTail

        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subtitleLabel)
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        update(title: title, subtitle: subtitle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let titleSize = titleLabel.intrinsicContentSize
        let subtitleSize = subtitleLabel.isHidden ? .zero : subtitleLabel.intrinsicContentSize
        let width = max(titleSize.width, subtitleSize.width)
        let height = titleSize.height + (subtitleLabel.isHidden ? 0 : subtitleSize.height + stack.spacing)
        return CGSize(width: ceil(width) + 1, height: ceil(height))
    }

    func update(title: String? = nil, subtitle: String? = nil) {
        if let title = title {
            titleLabel.text = title
        }
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = (subtitle ?? "").isEmpty
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
}
