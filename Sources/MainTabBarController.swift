import UIKit

/// 底部两个 Tab：精华 / 论坛
final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    private let lastTabKey = "fb_last_tab"

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func make() -> MainTabBarController {
        let tab = MainTabBarController(nibName: nil, bundle: nil)

        let digestNav = UINavigationController(rootViewController: DigestViewController(style: .plain))
        digestNav.tabBarItem = UITabBarItem(title: "精华",
                                            image: UIImage(systemName: "sparkles"),
                                            selectedImage: UIImage(systemName: "sparkles"))

        let sitesNav = UINavigationController(rootViewController: SitesViewController(style: .plain))
        sitesNav.tabBarItem = UITabBarItem(title: "论坛",
                                           image: UIImage(systemName: "list.bullet"),
                                           selectedImage: UIImage(systemName: "list.bullet"))

        let favoriteNav = UINavigationController(rootViewController: FavoritesViewController(style: .plain))
        favoriteNav.tabBarItem = UITabBarItem(title: "收藏",
                                              image: UIImage(systemName: "star"),
                                              selectedImage: UIImage(systemName: "star.fill"))

        tab.viewControllers = [digestNav, sitesNav, favoriteNav]
        return tab
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        let saved = UserDefaults.standard.integer(forKey: lastTabKey)
        selectedIndex = min(max(saved, 0), 2)
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        UserDefaults.standard.set(selectedIndex, forKey: lastTabKey)
    }
}
