import UIKit
import PhotosUI

/// 设置页：外观（主题 / 字体 / 字号 / 背景图）、站点管理、关于
final class SettingsViewController: UITableViewController, ScrollToTopable {

    private enum Row {
        case appIcon
        case appName
        case theme
        case font
        case fontSize
        case background
        case removeBackground
        case resetAppearance
        case videoPlayer
        case manageVideoSites
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

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { Theme.statusBarStyle }

    private func setupHeader() {
        let width = max(tableView.bounds.width, view.bounds.width)
        let header = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 58))
        header.backgroundColor = .clear

        headerTitleLabel.text = "设置"
        headerTitleLabel.font = Theme.rounded(20, .bold)
        headerTitleLabel.textColor = Theme.text
        headerTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(headerTitleLabel)

        headerSubtitleLabel.text = "\(AppSettings.shared.appDisplayName) · 外观、视频与站点"
        headerSubtitleLabel.lineBreakMode = .byTruncatingTail
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
        let personalization: [Row] = [.appIcon, .appName]
        var appearance: [Row] = [.theme, .font, .fontSize, .background]
        if AppSettings.shared.hasBackground {
            appearance.append(.removeBackground)
        }
        appearance.append(.resetAppearance)
        rows = [personalization, appearance, [.videoPlayer], [.manageVideoSites, .manageSites], [.version]]
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
        case 0: return "个性化"
        case 1: return "外观"
        case 2: return "视频"
        case 3: return "站点"
        default: return "关于"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 0 ? "桌面图标名称由 iOS 固定；这里的名称只影响 App 内显示。" : nil
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
        case .appIcon:
            cell.configure(title: "软件图标",
                           value: AppIcons.currentName,
                           showsChevron: true,
                           icon: "app.badge")
        case .appName:
            cell.configure(title: "软件名称",
                           value: AppSettings.shared.appDisplayName,
                           showsChevron: true,
                           icon: "textformat.abc")
        case .theme:
            cell.configure(title: "主题", value: ThemeManager.shared.style.displayName, showsChevron: true, icon: "paintpalette.fill")
        case .font:
            cell.configure(title: "字体", value: AppSettings.shared.fontChoice.displayName, showsChevron: true, icon: "textformat")
        case .fontSize:
            cell.configure(title: "字号", value: AppSettings.shared.fontScaleName, showsChevron: true, icon: "textformat.size")
        case .background:
            cell.configure(title: "背景图",
                           value: AppSettings.shared.hasBackground ? "已设置" : "未设置",
                           showsChevron: true,
                           icon: "photo.fill")
        case .removeBackground:
            cell.configure(title: "移除背景图", value: nil, showsChevron: false, destructive: true, icon: "trash")
        case .resetAppearance:
            cell.configure(title: "恢复默认外观", value: nil, showsChevron: false, destructive: true, icon: "arrow.counterclockwise")
        case .videoPlayer:
            cell.configure(title: "视频播放器",
                           value: AppSettings.shared.videoPlayerName,
                           showsChevron: true,
                           icon: "play.rectangle.fill")
        case .manageVideoSites:
            cell.configure(title: "视频站点",
                           value: "\(VideoSiteStore.shared.sites.count) 个站点",
                           showsChevron: true,
                           icon: "rectangle.stack")
        case .manageSites:
            cell.configure(title: "论坛站点", value: "\(Sites.all.count) 个站点", showsChevron: true, icon: "globe")
        case .version:
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
            cell.configure(title: "版本", value: "\(version) (\(build))", showsChevron: false, icon: "info.circle")
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = rows[indexPath.section][indexPath.row]
        switch row {
        case .appIcon:
            navigationController?.pushViewController(AppIconPickerViewController(), animated: true)
        case .appName:
            presentNamePicker()
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
        case .resetAppearance:
            confirmResetAppearance()
        case .videoPlayer:
            presentVideoPlayerPicker()
        case .manageVideoSites:
            navigationController?.pushViewController(VideoSitesViewController(style: .insetGrouped),
                                                     animated: true)
        case .manageSites:
            let controller = SitesViewController(style: .insetGrouped)
            controller.managementMode = true
            navigationController?.pushViewController(controller, animated: true)
        case .version:
            break
        }
    }

    // MARK: - 选择器

    private func presentNamePicker() {
        let presets = ["论坛盒子", "盒子", "小盒子", "夜航盒子", "樱花盒子", "奶油盒子", "赛博盒子"]
        let sheet = UIAlertController(title: "软件名称",
                                      message: "App 内显示名称；桌面图标下方名称由 iOS 固定。",
                                      preferredStyle: .actionSheet)
        for name in presets {
            let title = name == AppSettings.shared.appDisplayName ? "\(name)  ✓" : name
            sheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.applyAppName(name)
            })
        }
        sheet.addAction(UIAlertAction(title: "自定义…", style: .default) { [weak self] _ in
            self?.presentCustomName()
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(sheet, animated: true)
    }

    private func presentCustomName() {
        let alert = UIAlertController(title: "自定义软件名称", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "输入名称"
            field.text = AppSettings.shared.appDisplayName
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self, weak alert] _ in
            let name = alert?.textFields?.first?.text?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { return }
            self?.applyAppName(String(name.prefix(12)))
        })
        present(alert, animated: true)
    }

    private func applyAppName(_ name: String) {
        AppSettings.shared.appDisplayName = name
        headerSubtitleLabel.text = "\(name) · 外观、视频与站点"
        tableView.reloadData()
        Haptics.success()
    }

    private func presentVideoPlayerPicker() {
        let sheet = UIAlertController(title: "视频打开方式",
                                      message: "系统播放器兼容性更好；内置播放器支持广告拦截。",
                                      preferredStyle: .actionSheet)
        let system = AppSettings.shared.videoUseSystemPlayer ? "系统播放器（兼容）  ✓" : "系统播放器（兼容）"
        sheet.addAction(UIAlertAction(title: system, style: .default) { [weak self] _ in
            AppSettings.shared.videoUseSystemPlayer = true
            self?.tableView.reloadData()
        })
        let builtin = AppSettings.shared.videoUseSystemPlayer ? "内置播放器（去广告）" : "内置播放器（去广告）  ✓"
        sheet.addAction(UIAlertAction(title: builtin, style: .default) { [weak self] _ in
            AppSettings.shared.videoUseSystemPlayer = false
            self?.tableView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        }
        present(sheet, animated: true)
    }

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

    private func confirmResetAppearance() {
        let alert = UIAlertController(title: "恢复默认外观？",
                                      message: "主题、字体、字号、背景图都会恢复默认。",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "恢复", style: .destructive) { [weak self] _ in
            ThemeManager.shared.setStyle(.southPlus)
            AppSettings.shared.fontChoice = .automatic
            AppSettings.shared.fontScale = 1.0
            AppSettings.shared.clearBackground()
            ThemePicker.rebuildRoot(from: self)
        })
        present(alert, animated: true)
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

    private let iconBackground = UIView()
    private let iconView = UIImageView()
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

        iconBackground.backgroundColor = Theme.tonal
        iconBackground.layer.cornerRadius = 8
        iconBackground.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconBackground)

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBackground.addSubview(iconView)

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
            iconBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconBackground.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 28),
            iconBackground.heightAnchor.constraint(equalToConstant: 28),

            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),

            titleLabel.leadingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: 12),
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

    func configure(title: String,
                   value: String?,
                   showsChevron: Bool,
                   destructive: Bool = false,
                   icon: String? = nil) {
        titleLabel.text = title
        titleLabel.textColor = destructive ? UIColor.systemRed : Theme.text
        valueLabel.text = value
        valueLabel.isHidden = (value ?? "").isEmpty
        chevronLabel.isHidden = !showsChevron
        iconView.image = icon.flatMap { UIImage(systemName: $0) }
        iconView.tintColor = destructive ? UIColor.systemRed : Theme.accent
        iconBackground.backgroundColor = destructive
            ? UIColor.systemRed.withAlphaComponent(0.10)
            : Theme.tonal
    }
}
