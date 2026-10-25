import UIKit
import SafariServices

/// 统一打开视频：系统播放器 / 内置播放器
enum VideoOpener {

    static func open(url: URL,
                     title: String,
                     from presenter: UIViewController,
                     navigation: UINavigationController?) {
        Haptics.tap()
        CrashLogger.log("open video \(url.absoluteString) system=\(AppSettings.shared.videoUseSystemPlayer)")

        if AppSettings.shared.videoUseSystemPlayer {
            let safari = SFSafariViewController(url: url)
            safari.preferredControlTintColor = Theme.accent
            safari.modalPresentationStyle = .fullScreen
            presenter.present(safari, animated: true) {
                CrashLogger.log("safari presented \(url.absoluteString)")
            }
            return
        }

        guard let navigation = navigation else { return }
        let controller = WebViewController(title: title,
                                           urlString: url.absoluteString,
                                           videoMode: true)
        navigation.pushViewController(controller, animated: true)
    }
}
