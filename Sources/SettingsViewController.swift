import UIKit
import PhotosUI

/// 设置页：外观（主题 / 字体 / 字号 / 背景图）、站点管理、关于
final class SettingsViewController: UITableViewController {

    private enum Row {
        case theme
        case font
        case fontSize
        case background
        case removeBackground
        case manageSites
        case version
    }

    private var rows: [[Row]] = []
    private let headerTitleLabel = UILabel()
    private let headerSubtitleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "设置"
        navigationItem.title = "设置"
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItems = nil
        view.backgroundColor = Theme.bgTop
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Theme.cardBorder
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.rowHeight = 52 * AppSettings.shared.fontScale
        tableView.sectionHeaderTopPadding = 12
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.register(SettingRowCell.self, forCellReuseIdentifier: SettingRowCell.reuseID)
        tableView.backgroundView = Theme.makeBackgroundView(tableView.bounds)
        setupHeader()
        rebuildRows()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        rebuildRows()
        tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.backgroundView?.frame = tableView.bounds
        if let header = tableView.tableHeaderView, header.frame.width != tableView.bounds.width {
            header.frame.size.width = tableView.bounds.width
            tableView.tableHeaderView = header
        }
    }

    private func setupHeader() {
        let width = max(tableView.bounds.width, view.bounds.width)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 58))
        header.backgroundColor = .clear

        headerTitleLabel.text = "设置"
        headerTitleLabel.font = Theme.rounded(20, .bold)
        headerTitleLabel.textColor = Theme.text
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerTitleLabel)

        headerSubtitleLabel.text = "主题、字体、背景与站点"
        headerSubtitleLabel.font = Theme.font(12, .regular)
        headerSubtitleLabel.textColor = Theme.textDim
        headerSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerSubtitleLabel)

        NSLayoutConstraint.activate([
            headerTitleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
            headerTitleLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 6),
            headerTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -16),

            headerSubtitleLabel.leadingAnchor.constraint(equalTo: headerTitleLabel.leadingAnchor),
            headerSubtitleLabel.topAnchor.constraint(equalTo: headerTitleLabel.bottomAnchor, constant: 0),
            headerSubtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: header.trailingAnchor, constant: -16)
        ])

        tableView.tableHeaderView = header
    }

    private func rebuildRows() {
        var appearance: [Row] = [.theme, .font, .fontSize, .background]
        if AppSettings.shared.hasBackground {
            appearance.append(.removeBackground)
        }
        rows = [appearance, [.manageSites], [.version]]
    }

    // MARK: - 表格

    override func numberOfSections(in tableView: UITableView) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows[section].count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "外观"
        case 1: return "论坛"
        default: return "关于"
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.font = Theme.font(13, .semibold)
        header.textLabel?.textColor = Theme.textDim
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingRowCell.reuseID,
                                                 for: indexPath) as! SettingRowCell
        let row = rows[indexPath.section][indexPath.row]
        switch row {
        case .theme:
            cell.configure(title: "主题", value: ThemeManager.shared.style.displayName, showsChevron: true)
        case .font:
            cell.configure(title: "字体", value: AppSettings.shared.fontChoice.displayName, showsChevron: true)
        case .fontSize:
            cell.configure(title: "字号", value: AppSettings.shared.fontScaleName, showsChevron: true)
        case .background:
            cell.configure(title: "背景图",
                           value: AppSettings.shared.hasBackground ? "已设置" : "未设置",
                           showsChevron: true)
        case .removeBackground:
            cell.configure(title: "移除背景图", value: nil, showsChevron: false, destructive: true)
        case .manageSites:
            cell.configure(title: "站点管理", value: "\(Sites.all.count) 个站点", showsChevron: true)
        case .version:
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
            cell.configure(title: "版本", value: "\(version) (\(build))", showsChevron: false)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = rows[indexPath.section][indexPath.row]
        switch row {
        case .theme:
            ThemePicker.present(from: self, sourceView: tableView.cellForRow(at: indexPath) ?? view)
        case .font:
            presentFontPicker()
        case .fontSize:
            presentSizePicker()
        case .background:
            presentPhotoPicker()
        case .removeBackground:
            AppSettings.shared.clearBackground()
            ThemePicker.rebuildRoot(from: self)
        case .manageSites:
            let controller = SitesViewController(style: .insetGrouped)
            controller.managementMode = true
            navigationController?.pushViewController(controller, animated: true)
        case .version:
            break
        }
    }

    // MARK: - 选择器

    private func presentFontPicker() {
        let sheet = UIAlertController(title: "选择字体", message: nil, preferredStyle: .actionSheet)
        for choice in AppFontChoice.allCases {
            let isCurrent = AppSettings.shared.fontChoice == choice
            let title = isCurrent ? "\(choice.displayName)  ✓" : choice.displayName
            sheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                AppSettings.shared.fontChoice = choice
                ThemePicker.rebuildRoot(from: self)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(sheet, animated: true)
    }

    private func presentSizePicker() {
        let sheet = UIAlertController(title: "选择字号", message: nil, preferredStyle: .actionSheet)
        for option in AppSettings.scaleOptions {
            let isCurrent = abs(AppSettings.shared.fontScale - option.value) < 0.01
            let title = isCurrent ? "\(option.name)  ✓" : option.name
            sheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                AppSettings.shared.fontScale = option.value
                ThemePicker.rebuildRoot(from: self)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(sheet, animated: true)
    }

    private func presentPhotoPicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension SettingsViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                AppSettings.shared.saveBackground(image)
                ThemePicker.rebuildRoot(from: self)
            }
        }
    }
}

/// 设置行：标题 + 右侧值 + 箭头
final class SettingRowCell: UITableViewCell {

    static let reuseID = "SettingRowCell"

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let chevronLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = Theme.card
        contentView.backgroundColor = Theme.card
        selectionStyle = .default
        let selected = UIView()
        selected.backgroundColor = Theme.tonal
        selectedBackgroundView = selected

        titleLabel.font = Theme.rounded(15, .medium)
        titleLabel.textColor = Theme.text
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = Theme.font(13, .regular)
        valueLabel.textColor = Theme.textDim
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        chevronLabel.text = "›"
        chevronLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        chevronLabel.textColor = Theme.textFaint
        chevronLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(valueLabel)
        contentView.addSubview(chevronLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            chevronLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            chevronLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            chevronLabel.widthAnchor.constraint(equalToConstant: 10),

            valueLabel.trailingAnchor.constraint(equalTo: chevronLabel.leadingAnchor, constant: -6),
            valueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, value: String?, showsChevron: Bool, destructive: Bool = false) {
        titleLabel.text = title
        titleLabel.textColor = destructive ? UIColor.systemRed : Theme.text
        valueLabel.text = value
        valueLabel.isHidden = (value ?? "").isEmpty
        chevronLabel.isHidden = !showsChevron
    }
}
