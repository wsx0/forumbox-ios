import UIKit

/// 软件图标选择
final class AppIconPickerViewController: UICollectionViewController {

    private let options = AppIcons.all

    init() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 14
        layout.sectionInset = UIEdgeInsets(top: 26, left: 16, bottom: 32, right: 16)
        super.init(collectionViewLayout: layout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "软件图标"
        navigationItem.title = "软件图标"
        view.backgroundColor = Theme.bgTop
        collectionView.backgroundColor = .clear
        collectionView.backgroundView = Theme.makeBackgroundView(collectionView.bounds)
        collectionView.register(AppIconCell.self,
                                forCellWithReuseIdentifier: AppIconCell.reuseID)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        collectionView.reloadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.backgroundView?.frame = collectionView.bounds
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let spacing: CGFloat = 12
        let available = collectionView.bounds.width - 32 - spacing * 2
        let width = max(88, available / 3)
        let target = CGSize(width: width, height: 126)
        if layout.itemSize != target {
            layout.itemSize = target
            layout.invalidateLayout()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return options.count
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AppIconCell.reuseID,
                                                      for: indexPath) as! AppIconCell
        let option = options[indexPath.item]
        cell.configure(option: option,
                       selected: AppIcons.currentKey == option.key)
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        apply(options[indexPath.item])
    }

    private func apply(_ option: AppIconOption) {
        guard AppIcons.currentKey != option.key else { return }
        guard UIApplication.shared.supportsAlternateIcons else {
            presentNotice("当前设备不支持更换图标")
            return
        }
        Haptics.tap()
        UIApplication.shared.setAlternateIconName(option.key) { [weak self] error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.presentNotice("图标切换失败：\(error.localizedDescription)")
                    return
                }
                Haptics.success()
                self.collectionView.reloadData()
            }
        }
    }

    private func presentNotice(_ text: String) {
        let alert = UIAlertController(title: "提示", message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}

/// 图标格子
final class AppIconCell: UICollectionViewCell {

    static let reuseID = "AppIconCell"

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let checkView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = Theme.card
        contentView.layer.cornerRadius = 18
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = Theme.cardBorder.cgColor
        contentView.layer.masksToBounds = true

        iconView.contentMode = .scaleAspectFill
        iconView.layer.cornerRadius = 16
        iconView.clipsToBounds = true
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)

        nameLabel.font = Theme.font(11, .medium)
        nameLabel.textColor = Theme.textDim
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        checkView.image = UIImage(systemName: "checkmark.circle.fill")
        checkView.tintColor = Theme.accent
        checkView.backgroundColor = Theme.card
        checkView.layer.cornerRadius = 9
        checkView.clipsToBounds = true
        checkView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkView)

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 72),
            iconView.heightAnchor.constraint(equalToConstant: 72),

            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),

            checkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            checkView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            checkView.widthAnchor.constraint(equalToConstant: 18),
            checkView.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(option: AppIconOption, selected: Bool) {
        iconView.image = AppIcons.preview(for: option)
        nameLabel.text = option.name
        checkView.isHidden = !selected
        contentView.layer.borderColor = selected
            ? Theme.accent.cgColor
            : Theme.cardBorder.cgColor
        contentView.layer.borderWidth = selected ? 2 : 1
    }
}
