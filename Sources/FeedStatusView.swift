import UIKit

/// 加载中 / 空状态提示（浮在列表中央）
final class FeedStatusView: UIView {

    private let spinner = UIActivityIndicatorView(style: .medium)
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false

        spinner.color = Theme.accent
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)

        label.font = Theme.rounded(13, .medium)
        label.textColor = Theme.textFaint
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -22),
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ text: String, spinning: Bool) {
        label.text = text
        isHidden = false
        if spinning {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    func hide() {
        isHidden = true
        spinner.stopAnimating()
    }
}
