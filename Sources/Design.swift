import UIKit

/// 触感反馈
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

/// 底部 Tab 图标（统一缩小尺寸，更精致）
enum TabIcon {
    static func image(_ name: String) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        return UIImage(systemName: name, withConfiguration: config)
    }
}
