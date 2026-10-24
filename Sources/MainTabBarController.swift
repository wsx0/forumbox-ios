import UIKit

/// 底部两个 Tab：论坛 / 收藏
final class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    private let lastTabKey = "fb_last_tab"
    private var favoritesObserver: NSObjectProtocol?

    deinit {
        if let observer = favoritesObserver {
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

        let sitesNav = UINavigationController(rootViewController: SitesViewController(style: .plain))
        sitesNav.tabBarItem = UITabBarItem(title: "论坛",
                                           image: TabIcon.image("text.bubble"),
                                           selectedImage: TabIcon.image("text.bubble"))

        let favoriteNav = UINavigationController(rootViewController: FavoritesViewController(style: .plain))
        favoriteNav.tabBarItem = UITabBarItem(title: "收藏",
                                              image: TabIcon.image("star"),
                                              selectedImage: TabIcon.image("star.fill"))

        tab.viewControllers = [sitesNav, favoriteNav]
        return tab
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBar.itemPositioning = .fill
        let saved = UserDefaults.standard.integer(forKey: lastTabKey)
        selectedIndex = min(max(saved, 0), 1)
        updateFavoriteBadge()
        favoritesObserver = NotificationCenter.default.addObserver(forName: .favoritesChanged,
                                                                  object: nil,
                                                                  queue: .main) { [weak self] _ in
            self?.updateFavoriteBadge()
        }
    }

    private func updateFavoriteBadge() {
        let count = FavoriteStore.shared.items.count
        viewControllers?.last?.tabBarItem.badgeValue = count > 0 ? "\(count)" : nil
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        UserDefaults.standard.set(selectedIndex, forKey: lastTabKey)
        Haptics.tap()
    }
}
