import UIKit

/// 横向筛选 chips（全部 / 各论坛）
final class FilterChipsView: UIView {

    struct Item {
        let title: String
    }

    private let scrollView = UIScrollView()
    private let stack = UIStackView()
    private var buttons: [UIButton] = []
    private var items: [Item] = []
    private var lastTitles: [String] = []
    private(set) var selectedIndex = 0
    var onSelect: ((Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scrollView)

        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: Design.hPad),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -Design.hPad),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(items: [Item], selected: Int) {
        let titles = items.map { $0.title }
        self.items = items
        selectedIndex = min(max(selected, 0), max(items.count - 1, 0))

        // 标题没变时只更新选中状态，避免反复重建按钮
        if titles == lastTitles {
            updateStyles()
            return
        }
        lastTitles = titles

        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(item.title, for: .normal)
            button.titleLabel?.font = Theme.rounded(12.5, .semibold)
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
            button.layer.cornerRadius = Design.chipHeight / 2
            button.layer.borderWidth = 1
            button.layer.masksToBounds = true
            button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            buttons.append(button)
            stack.addArrangedSubview(button)
        }
        updateStyles()
    }

    @objc private func tapped(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        updateStyles()
        Haptics.tap()
        onSelect?(sender.tag)
    }

    private func updateStyles() {
        for (index, button) in buttons.enumerated() {
            let selected = index == selectedIndex
            button.backgroundColor = selected ? Theme.accent : Theme.card
            button.layer.borderColor = selected ? UIColor.clear.cgColor : Theme.cardBorder.cgColor
            button.setTitleColor(selected ? Theme.onAccent : Theme.textDim, for: .normal)
        }
    }
}
