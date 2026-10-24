import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Theme.applyAppearance()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.tintColor = Theme.accent
        window.rootViewController = MainTabBarController.make()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
