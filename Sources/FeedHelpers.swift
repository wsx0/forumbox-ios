import UIKit

/// 全局通知（收藏 / 站点变更）
extension Notification.Name {
    static let favoritesChanged = Notification.Name("fb.favoritesChanged")
    static let sitesChanged = Notification.Name("fb.sitesChanged")
}

/// 搜索共用的数据整理逻辑
enum FeedPipeline {

    /// 各站结果交错合并（每个站轮流取一条），避免全挤在同一个站
    static func entries(from results: [SiteThreadResult]) -> [FeedEntry] {
        let perSite: [[FeedEntry]] = results.map { result in
            result.items.map { FeedEntry(site: result.site, item: $0) }
        }
        var entries: [FeedEntry] = []
        var index = 0
        while true {
            var added = false
            for list in perSite where index < list.count {
                entries.append(list[index])
                added = true
            }
            if !added { break }
            index += 1
        }
        return entries
    }

    /// 失败站点的摘要文案（如 "JavBus 论坛 需要登录，x999x 无结果"）
    static func failedStatusText(_ results: [SiteThreadResult], pendingStatus: String = "抓取中…") -> String? {
        let failed = results.filter { $0.items.isEmpty && $0.status != pendingStatus }
        guard !failed.isEmpty else { return nil }
        return failed.prefix(2).map { "\($0.site.name) \($0.status)" }.joined(separator: "，")
    }
}

/// 通用轻提示弹窗
extension UIViewController {
    func presentNotice(_ text: String, title: String = "提示") {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}

/// URL 展示（去掉协议头）
extension String {
    var shortURL: String {
        if hasPrefix("https://") { return String(dropFirst(8)) }
        if hasPrefix("http://") { return String(dropFirst(7)) }
        return self
    }
}
