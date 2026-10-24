import UIKit

/// 设计常量
enum Design {
    static let hPad: CGFloat = 16
    static let cardCorner: CGFloat = 14
    static let cardSpacing: CGFloat = 8
    static let rowHeight: CGFloat = 82
    static let feedRowHeight: CGFloat = 78
    static let sectionHeaderHeight: CGFloat = 34
    static let chipHeight: CGFloat = 30
    static let headerHeight: CGFloat = 84
}

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
