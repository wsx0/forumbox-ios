import UIKit

/// 底部三个 Tab：论坛 / 视频 / 设置
final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    private let lastTabKey = "fb_last_tab_v4"

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func make() -> MainTabBarController {
        let tab = MainTabBarController(nibName: nil, bundle: nil)

        let sitesNav = UINavigationController(rootViewController: SitesViewController(style: .insetGrouped))
        sitesNav.tabBarItem = UITabBarItem(title: "论坛",
                                           image: TabIcon.image("text.bubble"),
                                           selectedImage: TabIcon.image("text.bubble.fill"))

        let videoNav = UINavigationController(rootViewController: VideoViewController())
        videoNav.tabBarItem = UITabBarItem(title: "视频",
                                           image: TabIcon.image("play.rectangle"),
                                           selectedImage: TabIcon.image("play.rectangle.fill"))

        let settingsNav = UINavigationController(rootViewController: SettingsViewController(style: .insetGrouped))
        settingsNav.tabBarItem = UITabBarItem(title: "设置",
                                              image: TabIcon.image("gearshape"),
                                              selectedImage: TabIcon.image("gearshape.fill"))

        tab.viewControllers = [sitesNav, videoNav, settingsNav]
        return tab
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.itemPositioning = .fill
        let saved = UserDefaults.standard.integer(forKey: lastTabKey)
        selectedIndex = min(max(saved, 0), 2)
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        UserDefaults.standard.set(selectedIndex, forKey: lastTabKey)
        CrashLogger.log("tab selected \(selectedIndex)")
        Haptics.tap()
    }

    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool {
        if viewController === selectedViewController {
            if let nav = viewController as? UINavigationController,
               let top = nav.topViewController as? ScrollToTopable {
                top.scrollToTop()
            }
            Haptics.tap()
            return false
        }
        return true
    }
}
