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
        let sheet = UIAlertController(title: "选择主题", message: nil, preferredStyle: .actionSheet)
        for style in ThemeManager.Style.allCases {
            let isCurrent = ThemeManager.shared.style == style
            let title = isCurrent ? "\(style.displayName)  ✓" : style.displayName
            sheet.addAction(UIAlertAction(title: title, style: .default) { [weak viewController] _ in
                apply(style, in: viewController)
            })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.barButtonItem = sourceItem
        }
        viewController.present(sheet, animated: true)
    }

    static func apply(_ style: ThemeManager.Style, in viewController: UIViewController?) {
        ThemeManager.shared.setStyle(style)
        Theme.applyAppearance()

        guard let window = viewController?.view.window else { return }
        let root = MainTabBarController.make()
        window.rootViewController = root
        window.tintColor = Theme.accent
        window.overrideUserInterfaceStyle = Theme.userInterfaceStyle
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }
}
