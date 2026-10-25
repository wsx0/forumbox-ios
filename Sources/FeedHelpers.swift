import UIKit

/// 全局通知（收藏 / 站点变更）
extension Notification.Name {
    static let favoritesChanged = Notification.Name("fb.favoritesChanged")
    static let sitesChanged = Notification.Name("fb.sitesChanged")
}

/// 通用轻提示弹窗
extension UIViewController {
    func presentNotice(_ text: String, title: String = "提示") {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}

/// 重新点击当前 Tab 时回到顶部
protocol ScrollToTopable {
    func scrollToTop()
}

extension ScrollToTopable where Self: UITableViewController {
    func scrollToTop() {
        let top = -tableView.adjustedContentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: top), animated: true)
    }
}

/// URL 展示（去掉协议头）
extension String {
    /// 列表头像用的首字（跳过【】括号等符号）
    var identityInitial: String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        let skipped = Set("【】[]（）()「」『』《》〈〉“”\"'#*·-— ")
        if let first = trimmed.first(where: { !skipped.contains($0) }) {
            return String(first).uppercased()
        }
        return "·"
    }
}
