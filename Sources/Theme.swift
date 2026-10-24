import UIKit

/// 二次元夜樱主题
enum Theme {
    static let bgTop = UIColor(red: 26/255, green: 19/255, blue: 51/255, alpha: 1)        // #1a1333
    static let bgBottom = UIColor(red: 16/255, green: 12/255, blue: 34/255, alpha: 1)     // #100c22
    static let card = UIColor(red: 40/255, green: 30/255, blue: 76/255, alpha: 0.93)      // #281e4c
    static let cardBorder = UIColor(red: 255/255, green: 143/255, blue: 177/255, alpha: 0.22)
    static let accent = UIColor(red: 255/255, green: 111/255, blue: 165/255, alpha: 1)    // #ff6fa5
    static let accentSoft = UIColor(red: 124/255, green: 92/255, blue: 255/255, alpha: 1) // #7c5cff
    static let text = UIColor(red: 246/255, green: 241/255, blue: 255/255, alpha: 1)
    static let textDim = UIColor(red: 186/255, green: 174/255, blue: 224/255, alpha: 1)
    static let textFaint = UIColor(red: 139/255, green: 126/255, blue: 181/255, alpha: 1)
    static let navBg = UIColor(red: 22/255, green: 16/255, blue: 42/255, alpha: 1)
    static let emojiBg = UIColor(red: 124/255, green: 92/255, blue: 255/255, alpha: 0.24)

    static func rounded(_ size: CGFloat, _ weight: UIFont.Weight = .bold) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }

    /// 带樱花水印的背景视图（用作 tableView.backgroundView）
    static func makeBackgroundView(_ frame: CGRect) -> UIView {
        let container = UIView(frame: frame)
        container.backgroundColor = bgTop
        if let image = UIImage(named: "BGSakura") {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.frame = container.bounds
            container.addSubview(imageView)
        }
        return container
    }

    /// 应用全局导航栏 / 状态栏风格
    static func applyAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navBg
        appearance.shadowColor = UIColor(red: 255/255, green: 143/255, blue: 177/255, alpha: 0.16)
        appearance.titleTextAttributes = [
            .foregroundColor: text,
            .font: rounded(17)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: text,
            .font: rounded(28)
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = accent
        UISearchBar.appearance().tintColor = accent
    }
}
