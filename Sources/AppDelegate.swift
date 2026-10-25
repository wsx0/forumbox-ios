import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CrashLogger.install()
        Theme.applyAppearance()

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.tintColor = Theme.accent
        window.overrideUserInterfaceStyle = Theme.userInterfaceStyle
        window.rootViewController = MainTabBarController.make()
        window.makeKeyAndVisible()
        self.window = window

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            CrashLogger.presentIfNeeded(from: self?.window?.rootViewController)
        }
        return true
    }
}
