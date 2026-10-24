import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Theme.applyAppearance()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.tintColor = Theme.accent
        let root = SitesViewController(style: .plain)
        let nav = UINavigationController(rootViewController: root)
        window.rootViewController = nav
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
