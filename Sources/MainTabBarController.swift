import UIKit

/// 底部四个 Tab：论坛 / 视频 / 收藏 / 设置
final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    private let lastTabKey = "fb_last_tab_v3"
    private var favoritesObserver: NSObjectProtocol?
    private var videoFavoritesObserver: NSObjectProtocol?

    deinit {
        if let observer = favoritesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = videoFavoritesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

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

        let favoriteNav = UINavigationController(rootViewController: FavoritesViewController(style: .insetGrouped))
        favoriteNav.tabBarItem = UITabBarItem(title: "收藏",
                                              image: TabIcon.image("star"),
                                              selectedImage: TabIcon.image("star.fill"))

        let settingsNav = UINavigationController(rootViewController: SettingsViewController(style: .insetGrouped))
        settingsNav.tabBarItem = UITabBarItem(title: "设置",
                                              image: TabIcon.image("gearshape"),
                                              selectedImage: TabIcon.image("gearshape.fill"))

        tab.viewControllers = [sitesNav, videoNav, favoriteNav, settingsNav]
        return tab
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.itemPositioning = .fill
        let saved = UserDefaults.standard.integer(forKey: lastTabKey)
        selectedIndex = min(max(saved, 0), 3)
        updateFavoriteBadge()
        favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesChanged,
                                                                  object: nil,
                                                                  queue: .main) { [weak self] _ in
            self?.updateFavoriteBadge()
        }
    }

    private func updateFavoriteBadge() {
        let count = FavoriteStore.shared.items.count + VideoFavoriteStore.shared.items.count
        viewControllers?[2].tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
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
