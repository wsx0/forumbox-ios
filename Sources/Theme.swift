import UIKit

/// 一套主题配色
struct Palette {
    let key: String
    let displayName: String
    let isLight: Bool
    let bgTop: UIColor
    let bgBottom: UIColor
    let card: UIColor
    let cardBorder: UIColor
    let accent: UIColor
    let accentSoft: UIColor
    let text: UIColor
    let textDim: UIColor
    let textFaint: UIColor
    let navBg: UIColor
    let emojiBg: UIColor
    let backgroundImageName: String?
    let showsPetals: Bool
}

final class ThemeManager {

    static let shared = ThemeManager()

    enum Style: String, CaseIterable {
        case southPlus, southPlusDark, sakura, sakuraLight, ocean, sky, cyber, cream, black

        var displayName: String {
            switch self {
            case .southPlus: return "简洁红"
            case .southPlusDark: return "简洁暗"
            case .sakura: return "夜樱"
            case .sakuraLight: return "樱白"
            case .ocean: return "深海蓝"
            case .sky: return "晴空"
            case .cyber: return "赛博紫"
            case .cream: return "奶油"
            case .black: return "纯黑"
            }
        }
    }

    private let storageKey = "fb_theme_style_v2"
    private(set) var style: Style

    private init() {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? ""
        style = Style(rawValue: raw) ?? .southPlus
    }

    var palette: Palette {
        switch style {
        case .southPlus:
            return Palette(
                key: "southPlus", displayName: "简洁红", isLight: true,
                bgTop: UIColor(red: 246/255, green: 246/255, blue: 247/255, alpha: 1),
                bgBottom: UIColor(red: 246/255, green: 246/255, blue: 247/255, alpha: 1),
                card: .white,
                cardBorder: UIColor(red: 226/255, green: 226/255, blue: 228/255, alpha: 1),
                accent: UIColor(red: 206/255, green: 48/255, blue: 56/255, alpha: 1),
                accentSoft: UIColor(red: 185/255, green: 52/255, blue: 69/255, alpha: 1),
                text: UIColor(red: 23/255, green: 23/255, blue: 23/255, alpha: 1),
                textDim: UIColor(red: 107/255, green: 111/255, blue: 118/255, alpha: 1),
                textFaint: UIColor(red: 154/255, green: 156/255, blue: 163/255, alpha: 1),
                navBg: UIColor(red: 246/255, green: 246/255, blue: 247/255, alpha: 1),
                emojiBg: UIColor(red: 255/255, green: 238/255, blue: 240/255, alpha: 1),
                backgroundImageName: nil,
                showsPetals: false)
        case .southPlusDark:
            return Palette(
                key: "southPlusDark", displayName: "简洁暗", isLight: false,
                bgTop: UIColor(red: 17/255, green: 17/255, blue: 20/255, alpha: 1),
                bgBottom: UIColor(red: 17/255, green: 17/255, blue: 20/255, alpha: 1),
                card: UIColor(red: 26/255, green: 27/255, blue: 32/255, alpha: 1),
                cardBorder: UIColor(red: 52/255, green: 54/255, blue: 61/255, alpha: 1),
                accent: UIColor(red: 255/255, green: 113/255, blue: 128/255, alpha: 1),
                accentSoft: UIColor(red: 255/255, green: 163/255, blue: 173/255, alpha: 1),
                text: UIColor(red: 243/255, green: 244/255, blue: 246/255, alpha: 1),
                textDim: UIColor(red: 184/255, green: 188/255, blue: 198/255, alpha: 1),
                textFaint: UIColor(red: 133/255, green: 139/255, blue: 151/255, alpha: 1),
                navBg: UIColor(red: 23/255, green: 24/255, blue: 29/255, alpha: 1),
                emojiBg: UIColor(red: 58/255, green: 26/255, blue: 32/255, alpha: 1),
                backgroundImageName: nil,
                showsPetals: false)
        case .sakura:
            return Palette(
                key: "sakura", displayName: "夜樱", isLight: false,
                bgTop: UIColor(red: 26/255, green: 19/255, blue: 51/255, alpha: 1),
                bgBottom: UIColor(red: 16/255, green: 12/255, blue: 34/255, alpha: 1),
                card: UIColor(red: 40/255, green: 30/255, blue: 76/255, alpha: 0.93),
                cardBorder: UIColor(red: 255/255, green: 143/255, blue: 177/255, alpha: 0.22),
                accent: UIColor(red: 255/255, green: 111/255, blue: 165/255, alpha: 1),
                accentSoft: UIColor(red: 124/255, green: 92/255, blue: 255/255, alpha: 1),
                text: UIColor(red: 246/255, green: 241/255, blue: 255/255, alpha: 1),
                textDim: UIColor(red: 186/255, green: 174/255, blue: 224/255, alpha: 1),
                textFaint: UIColor(red: 139/255, green: 126/255, blue: 181/255, alpha: 1),
                navBg: UIColor(red: 22/255, green: 16/255, blue: 42/255, alpha: 1),
                emojiBg: UIColor(red: 124/255, green: 92/255, blue: 255/255, alpha: 0.24),
                backgroundImageName: "BGSakura",
                showsPetals: true)
        case .sakuraLight:
            return Palette(
                key: "sakuraLight", displayName: "樱白", isLight: true,
                bgTop: UIColor(red: 255/255, green: 247/255, blue: 252/255, alpha: 1),
                bgBottom: UIColor(red: 255/255, green: 235/255, blue: 244/255, alpha: 1),
                card: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.95),
                cardBorder: UIColor(red: 240/255, green: 120/255, blue: 165/255, alpha: 0.25),
                accent: UIColor(red: 240/255, green: 98/255, blue: 146/255, alpha: 1),
                accentSoft: UIColor(red: 186/255, green: 104/255, blue: 200/255, alpha: 1),
                text: UIColor(red: 43/255, green: 36/255, blue: 55/255, alpha: 1),
                textDim: UIColor(red: 107/255, green: 98/255, blue: 120/255, alpha: 1),
                textFaint: UIColor(red: 154/255, green: 143/255, blue: 168/255, alpha: 1),
                navBg: UIColor(red: 255/255, green: 252/255, blue: 254/255, alpha: 1),
                emojiBg: UIColor(red: 255/255, green: 143/255, blue: 177/255, alpha: 0.16),
                backgroundImageName: nil,
                showsPetals: false)
        case .ocean:
            return Palette(
                key: "ocean", displayName: "深海蓝", isLight: false,
                bgTop: UIColor(red: 8/255, green: 36/255, blue: 59/255, alpha: 1),
                bgBottom: UIColor(red: 3/255, green: 16/255, blue: 28/255, alpha: 1),
                card: UIColor(red: 14/255, green: 42/255, blue: 68/255, alpha: 0.93),
                cardBorder: UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 0.24),
                accent: UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1),
                accentSoft: UIColor(red: 37/255, green: 99/255, blue: 235/255, alpha: 1),
                text: UIColor(red: 230/255, green: 244/255, blue: 255/255, alpha: 1),
                textDim: UIColor(red: 148/255, green: 190/255, blue: 220/255, alpha: 1),
                textFaint: UIColor(red: 100/255, green: 140/255, blue: 170/255, alpha: 1),
                navBg: UIColor(red: 5/255, green: 22/255, blue: 38/255, alpha: 1),
                emojiBg: UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 0.20),
                backgroundImageName: nil,
                showsPetals: false)
        case .sky:
            return Palette(
                key: "sky", displayName: "晴空", isLight: true,
                bgTop: UIColor(red: 244/255, green: 249/255, blue: 255/255, alpha: 1),
                bgBottom: UIColor(red: 232/255, green: 242/255, blue: 255/255, alpha: 1),
                card: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.95),
                cardBorder: UIColor(red: 46/255, green: 144/255, blue: 250/255, alpha: 0.22),
                accent: UIColor(red: 46/255, green: 144/255, blue: 250/255, alpha: 1),
                accentSoft: UIColor(red: 99/255, green: 102/255, blue: 241/255, alpha: 1),
                text: UIColor(red: 22/255, green: 34/255, blue: 58/255, alpha: 1),
                textDim: UIColor(red: 90/255, green: 110/255, blue: 140/255, alpha: 1),
                textFaint: UIColor(red: 130/255, green: 150/255, blue: 180/255, alpha: 1),
                navBg: UIColor(red: 250/255, green: 252/255, blue: 255/255, alpha: 1),
                emojiBg: UIColor(red: 46/255, green: 144/255, blue: 250/255, alpha: 0.14),
                backgroundImageName: nil,
                showsPetals: false)
        case .cyber:
            return Palette(
                key: "cyber", displayName: "赛博紫", isLight: false,
                bgTop: UIColor(red: 18/255, green: 7/255, blue: 31/255, alpha: 1),
                bgBottom: UIColor(red: 5/255, green: 3/255, blue: 10/255, alpha: 1),
                card: UIColor(red: 36/255, green: 16/255, blue: 64/255, alpha: 0.93),
                cardBorder: UIColor(red: 232/255, green: 121/255, blue: 249/255, alpha: 0.26),
                accent: UIColor(red: 232/255, green: 121/255, blue: 249/255, alpha: 1),
                accentSoft: UIColor(red: 168/255, green: 85/255, blue: 247/255, alpha: 1),
                text: UIColor(red: 245/255, green: 232/255, blue: 255/255, alpha: 1),
                textDim: UIColor(red: 200/255, green: 170/255, blue: 230/255, alpha: 1),
                textFaint: UIColor(red: 150/255, green: 120/255, blue: 185/255, alpha: 1),
                navBg: UIColor(red: 12/255, green: 5/255, blue: 22/255, alpha: 1),
                emojiBg: UIColor(red: 232/255, green: 121/255, blue: 249/255, alpha: 0.18),
                backgroundImageName: nil,
                showsPetals: false)
        case .cream:
            return Palette(
                key: "cream", displayName: "奶油", isLight: true,
                bgTop: UIColor(red: 255/255, green: 250/255, blue: 242/255, alpha: 1),
                bgBottom: UIColor(red: 255/255, green: 240/255, blue: 219/255, alpha: 1),
                card: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.95),
                cardBorder: UIColor(red: 240/255, green: 138/255, blue: 60/255, alpha: 0.22),
                accent: UIColor(red: 240/255, green: 138/255, blue: 60/255, alpha: 1),
                accentSoft: UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1),
                text: UIColor(red: 58/255, green: 46/255, blue: 34/255, alpha: 1),
                textDim: UIColor(red: 120/255, green: 100/255, blue: 80/255, alpha: 1),
                textFaint: UIColor(red: 160/255, green: 140/255, blue: 120/255, alpha: 1),
                navBg: UIColor(red: 255/255, green: 253/255, blue: 247/255, alpha: 1),
                emojiBg: UIColor(red: 240/255, green: 138/255, blue: 60/255, alpha: 0.14),
                backgroundImageName: nil,
                showsPetals: false)
        case .black:
            return Palette(
                key: "black", displayName: "纯黑", isLight: false,
                bgTop: .black,
                bgBottom: .black,
                card: UIColor(red: 17/255, green: 17/255, blue: 17/255, alpha: 0.96),
                cardBorder: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.12),
                accent: UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1),
                accentSoft: UIColor(red: 160/255, green: 160/255, blue: 160/255, alpha: 1),
                text: UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1),
                textDim: UIColor(red: 163/255, green: 163/255, blue: 163/255, alpha: 1),
                textFaint: UIColor(red: 115/255, green: 115/255, blue: 115/255, alpha: 1),
                navBg: .black,
                emojiBg: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.07),
                backgroundImageName: nil,
                showsPetals: false)
        }
    }

    func setStyle(_ newStyle: Style) {
        guard newStyle != style else { return }
        style = newStyle
        UserDefaults.standard.set(newStyle.rawValue, forKey: storageKey)
    }
}

/// 全局主题快捷入口（颜色全部跟随 ThemeManager）
enum Theme {

    static var palette: Palette { return ThemeManager.shared.palette }
    static var bgTop: UIColor { return palette.bgTop }
    static var bgBottom: UIColor { return palette.bgBottom }
    static var card: UIColor { return palette.card }
    static var cardBorder: UIColor { return palette.cardBorder }
    static var accent: UIColor { return palette.accent }
    static var accentSoft: UIColor { return palette.accentSoft }
    static var text: UIColor { return palette.text }
    static var textDim: UIColor { return palette.textDim }
    static var textFaint: UIColor { return palette.textFaint }
    static var navBg: UIColor { return palette.navBg }
    static var emojiBg: UIColor { return palette.emojiBg }

    /// 是否为「简洁」设计（SF 字体、Material 风格）
    static var isPlainStyle: Bool { return palette.key.hasPrefix("southPlus") }

    /// 次级按钮的填充色（Material tonal）
    static var tonal: UIColor {
        if palette.key == "southPlus" {
            return UIColor(red: 242/255, green: 242/255, blue: 244/255, alpha: 1)
        }
        if palette.key == "southPlusDark" {
            return UIColor(red: 35/255, green: 36/255, blue: 42/255, alpha: 1)
        }
        return palette.card
    }

    /// 主题亮色下的状态栏 / 键盘样式
    static var statusBarStyle: UIStatusBarStyle {
        return palette.isLight ? .darkContent : .lightContent
    }

    static var userInterfaceStyle: UIUserInterfaceStyle {
        return palette.isLight ? .light : .dark
    }

    static var keyboardAppearance: UIKeyboardAppearance {
        return palette.isLight ? .light : .dark
    }

    /// 强调色上应该用什么文字颜色
    static var onAccent: UIColor {
        if palette.key == "southPlus" { return .white }
        if palette.key == "southPlusDark" {
            // 参考 App 在暗色模式用深色字压在浅红主按钮上（对比度更高）
            return UIColor(red: 58/255, green: 13/255, blue: 22/255, alpha: 1)
        }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if palette.accent.getRed(&r, green: &g, blue: &b, alpha: &a) {
            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            return luminance > 0.66 ? .black : .white
        }
        return .white
    }

    static func rounded(_ size: CGFloat, _ weight: UIFont.Weight = .bold) -> UIFont {
        return AppSettings.shared.font(size: size, weight: weight)
    }

    /// 正文/说明字体（同样跟随设置里的字体与字号）
    static func font(_ size: CGFloat, _ weight: UIFont.Weight = .regular) -> UIFont {
        return AppSettings.shared.font(size: size, weight: weight)
    }

    /// 背景视图：自定义背景图 / 夜樱樱花图 / 纯色渐变
    static func makeBackgroundView(_ frame: CGRect) -> UIView {
        let palette = ThemeManager.shared.palette
        let container = UIView(frame: frame)
        container.backgroundColor = palette.bgTop

        if let custom = AppSettings.shared.backgroundImage {
            let imageView = UIImageView(image: custom)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.frame = container.bounds
            container.addSubview(imageView)

            let overlay = UIView(frame: container.bounds)
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.backgroundColor = palette.isLight
                ? UIColor.white.withAlphaComponent(0.55)
                : UIColor.black.withAlphaComponent(0.55)
            container.addSubview(overlay)
            return container
        }

        if let imageName = palette.backgroundImageName, let image = UIImage(named: imageName) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.frame = container.bounds
            container.addSubview(imageView)
        } else if palette.bgTop != palette.bgBottom {
            let gradient = GradientView(frame: container.bounds,
                                        top: palette.bgTop,
                                        bottom: palette.bgBottom)
            gradient.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.addSubview(gradient)
        }

        if palette.showsPetals {
            let petals = SakuraPetalView(frame: container.bounds)
            petals.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.addSubview(petals)
            petals.start()
        }
        return container
    }

    /// 应用导航栏 / 底部 Tab / 全局色调
    static func applyAppearance() {
        let palette = ThemeManager.shared.palette

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = palette.navBg
        appearance.shadowColor = palette.isLight ? UIColor(white: 0, alpha: 0.08) : palette.cardBorder
        appearance.titleTextAttributes = [.foregroundColor: palette.text,
                                          .font: rounded(17, .semibold)]
        appearance.largeTitleTextAttributes = [.foregroundColor: palette.text,
                                               .font: rounded(28, .bold)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = palette.textDim

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = palette.textFaint
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: palette.textDim,
                                                     .font: rounded(12, .medium)]
        itemAppearance.selected.iconColor = palette.accent
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: palette.accent,
                                                       .font: rounded(12, .semibold)]
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = palette.isLight ? palette.card : palette.navBg
        tabAppearance.shadowColor = palette.isLight ? UIColor(white: 0, alpha: 0.08) : palette.cardBorder
        tabAppearance.stackedLayoutAppearance = itemAppearance
        tabAppearance.inlineLayoutAppearance = itemAppearance
        tabAppearance.compactInlineLayoutAppearance = itemAppearance
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        UISearchBar.appearance().tintColor = palette.accent
    }
}
