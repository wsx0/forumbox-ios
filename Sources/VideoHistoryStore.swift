import Foundation

struct VideoEntry: Codable, Equatable {
    let id: UUID
    var title: String
    let url: String
    var watchedAt: Date
}

/// 视频观看记录（最近 40 条）
final class VideoHistoryStore {

    static let shared = VideoHistoryStore()

    private(set) var entries: [VideoEntry] = []
    private let storageKey = "fb_video_history_v1"
    private let limit = 40

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([VideoEntry].self, from: data) {
            entries = decoded
        }
    }

    @discardableResult
    func add(title: String, url: String) -> VideoEntry {
        if let index = entries.firstIndex(where: { $0.url == url }) {
            entries[index].title = title
            entries[index].watchedAt = Date()
            let item = entries.remove(at: index)
            entries.insert(item, at: 0)
            persist()
            return item
        }
        let entry = VideoEntry(id: UUID(), title: title, url: url, watchedAt: Date())
        entries.insert(entry, at: 0)
        if entries.count > limit {
            entries = Array(entries.prefix(limit))
        }
        persist()
        return entry
    }

    func updateTitle(url: String, title: String) {
        guard !title.isEmpty,
              let index = entries.firstIndex(where: { $0.url == url }),
              entries[index].title != title else { return }
        entries[index].title = title
        persist()
    }

    func remove(id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }

    func clear() {
        entries.removeAll()
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
