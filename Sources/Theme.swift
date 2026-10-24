import UIKit

/// 一套主题配色
struct Palette {
    let key: String
    let displayName: String
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
        case sakura, ocean, cyber, black

        var displayName: String {
            switch self {
            case .sakura: return "夜樱"
            case .ocean: return "深海蓝"
            case .cyber: return "赛博紫"
            case .black: return "纯黑"
            }
        }
    }

    private let storageKey = "fb_theme_style"
    private(set) var style: Style

    private init() {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? ""
        style = Style(rawValue: raw) ?? .sakura
    }

    var palette: Palette {
        switch style {
        case .sakura:
            return Palette(
                key: "sakura", displayName: "夜樱",
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
        case .ocean:
            return Palette(
                key: "ocean", displayName: "深海蓝",
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
        case .cyber:
            return Palette(
                key: "cyber", displayName: "赛博紫",
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
        case .black:
            return Palette(
                key: "black", displayName: "纯黑",
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

    static func rounded(_ size: CGFloat, _ weight: UIFont.Weight = .bold) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = base.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return base
    }

    /// 背景视图：夜樱 = 樱花图 + 飘落粒子；其他主题 = 渐变
    static func makeBackgroundView(_ frame: CGRect) -> UIView {
        let palette = ThemeManager.shared.palette
        let container = UIView(frame: frame)
        container.backgroundColor = palette.bgTop

        if let imageName = palette.backgroundImageName, let image = UIImage(named: imageName) {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            imageView.frame = container.bounds
            container.addSubview(imageView)
        } else {
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

    /// 应用导航栏 / 全局色调
    static func applyAppearance() {
        let palette = ThemeManager.shared.palette
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = palette.navBg
        appearance.shadowColor = palette.cardBorder
        appearance.titleTextAttributes = [.foregroundColor: palette.text, .font: rounded(17)]
        appearance.largeTitleTextAttributes = [.foregroundColor: palette.text, .font: rounded(28)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = palette.accent
        UISearchBar.appearance().tintColor = palette.accent
    }
}
