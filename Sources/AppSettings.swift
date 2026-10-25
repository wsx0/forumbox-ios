import UIKit

/// 可选字体
enum AppFontChoice: String, CaseIterable {
    case automatic, system, rounded, songti, kaiti

    var displayName: String {
        switch self {
        case .automatic: return "默认（跟随主题）"
        case .system: return "系统（苹方）"
        case .rounded: return "圆体"
        case .songti: return "宋体"
        case .kaiti: return "楷体"
        }
    }

    func font(size: CGFloat, weight: UIFont.Weight, plainStyle: Bool) -> UIFont {
        switch self {
        case .automatic:
            if plainStyle {
                return UIFont.systemFont(ofSize: size, weight: weight)
            }
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            if let descriptor = base.fontDescriptor.withDesign(.rounded) {
                return UIFont(descriptor: descriptor, size: size)
            }
            return base
        case .system:
            return UIFont.systemFont(ofSize: size, weight: weight)
        case .rounded:
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            if let descriptor = base.fontDescriptor.withDesign(.rounded) {
                return UIFont(descriptor: descriptor, size: size)
            }
            return base
        case .songti:
            return UIFont(name: "Songti SC", size: size) ?? UIFont.systemFont(ofSize: size, weight: weight)
        case .kaiti:
            return UIFont(name: "Kaiti SC", size: size) ?? UIFont.systemFont(ofSize: size, weight: weight)
        }
    }
}

/// 全局设置：字体、字号、自定义背景
final class AppSettings {

    static let shared = AppSettings()

    static let scaleOptions: [(value: CGFloat, name: String)] = [
        (0.90, "小"),
        (1.00, "标准"),
        (1.10, "大"),
        (1.20, "特大")
    ]

    private let fontChoiceKey = "fb_font_choice"
    private let fontScaleKey = "fb_font_scale"
    private let backgroundFileName = "fb_background.jpg"

    private init() {}

    // MARK: - 字体

    var fontChoice: AppFontChoice {
        get {
            let raw = UserDefaults.standard.string(forKey: fontChoiceKey) ?? ""
            return AppFontChoice(rawValue: raw) ?? .automatic
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: fontChoiceKey) }
    }

    var fontScale: CGFloat {
        get {
            let value = UserDefaults.standard.double(forKey: fontScaleKey)
            return value > 0 ? CGFloat(value) : 1.0
        }
        set { UserDefaults.standard.set(Double(newValue), forKey: fontScaleKey) }
    }

    var fontScaleName: String {
        let value = fontScale
        return Self.scaleOptions.first(where: { abs($0.value - value) < 0.01 })?.name ?? "标准"
    }

    /// 按用户选择缩放后的字体
    func font(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let scaled = size * fontScale
        return fontChoice.font(size: scaled, weight: weight, plainStyle: Theme.isPlainStyle)
    }

    // MARK: - 背景图

    private var backgroundURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(backgroundFileName)
    }

    var hasBackground: Bool {
        return FileManager.default.fileExists(atPath: backgroundURL.path)
    }

    var backgroundImage: UIImage? {
        guard hasBackground else { return nil }
        return UIImage(contentsOfFile: backgroundURL.path)
    }

    func saveBackground(_ image: UIImage) {
        let maxSide: CGFloat = 1800
        let side = max(image.size.width, image.size.height)
        let ratio = side > maxSide ? maxSide / side : 1
        let target = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        guard let data = resized.jpegData(compressionQuality: 0.86) else { return }
        try? data.write(to: backgroundURL, options: .atomic)
    }

    func clearBackground() {
        try? FileManager.default.removeItem(at: backgroundURL)
    }
}
