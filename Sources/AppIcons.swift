import UIKit

struct AppIconOption {
    let key: String?
    let name: String
    let previewName: String
}

enum AppIcons {
    static let all: [AppIconOption] = [
        AppIconOption(key: nil, name: "鲸鱼", previewName: "IconDefault"),
        AppIconOption(key: "IconSakura", name: "粉樱", previewName: "IconSakura"),
        AppIconOption(key: "IconCat", name: "猫耳", previewName: "IconCat"),
        AppIconOption(key: "IconMoon", name: "月白", previewName: "IconMoon"),
        AppIconOption(key: "IconStar", name: "星野", previewName: "IconStar"),
        AppIconOption(key: "IconCyber", name: "霓虹", previewName: "IconCyber"),
        AppIconOption(key: "IconBunny", name: "兔眠", previewName: "IconBunny"),
        AppIconOption(key: "IconMatcha", name: "抹茶", previewName: "IconMatcha"),
        AppIconOption(key: "IconPeach", name: "桃桃", previewName: "IconPeach"),
        AppIconOption(key: "IconOcean", name: "海音", previewName: "IconOcean"),
        AppIconOption(key: "IconPixel", name: "像素", previewName: "IconPixel")
    ]

    static var currentKey: String? {
        return UIApplication.shared.alternateIconName
    }

    static var currentName: String {
        return all.first(where: { $0.key == currentKey })?.name ?? "默认"
    }

    static func preview(for option: AppIconOption) -> UIImage? {
        let candidates = [
            option.previewName + "@3x",
            "AlternateIcons/" + option.previewName + "@3x"
        ]
        for name in candidates {
            if let path = Bundle.main.path(forResource: name, ofType: "png"),
               let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        return nil
    }
}
