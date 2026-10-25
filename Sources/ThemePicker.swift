import UIKit

/// 主题选择器（论坛页 / 收藏页 共用）
enum ThemePicker {

    static func makeButton(target: Any, action: Selector) -> UIBarButtonItem {
        return UIBarButtonItem(image: UIImage(systemName: "paintpalette"),
                               style: .plain,
                               target: target,
                               action: action)
    }

    static func present(from viewController: UIViewController, sourceItem: UIBarButtonItem) {
        let sheet = makeSheet(from: viewController)
        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = sourceItem
        }
        viewController.present(sheet, animated: true)
    }

    /// 从设置页的一行弹出
    static func present(from viewController: UIViewController, sourceView: UIView) {
        let sheet = makeSheet(from: viewController)
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sourceView
            pop.sourceRect = sourceView.bounds
        }
        viewController.present(sheet, animated: true)
    }

    private static func makeSheet(from viewController: UIViewController) -> UIAlertController {
        let sheet = UIAlertController(title: "选择主题", message: nil, preferredStyle: .actionSheet)
        for style in ThemeManager.Style.allCases {
            let isCurrent = ThemeManager.shared.style == style
            let title = isCurrent ? "\(style.displayName)  ✓" : style.displayName
            sheet.addAction(UIAlertAction(title: title, style: .default) { [weak viewController] _ in
                apply(style, in: viewController)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        return sheet
    }

    static func apply(_ style: ThemeManager.Style, in viewController: UIViewController?) {
        ThemeManager.shared.setStyle(style)
        rebuildRoot(from: viewController)
    }

    /// 主题 / 字体 / 字号 / 背景图变更后重建根界面
    static func rebuildRoot(from viewController: UIViewController?) {
        Theme.applyAppearance()

        guard let window = viewController?.view.window ?? keyWindow() else { return }
        let root = MainTabBarController.make()
        window.rootViewController = root
        window.tintColor = Theme.accent
        window.overrideUserInterfaceStyle = Theme.userInterfaceStyle
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }

    private static func keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
