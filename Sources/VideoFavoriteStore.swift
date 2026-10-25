import Foundation

struct VideoFavorite: Codable, Equatable {
    let id: UUID
    var title: String
    let url: String
    var thumbnailURL: String?
    let createdAt: Date
}

extension Notification.Name {
    static let videoFavoritesChanged = Notification.Name("fb_video_favorites_changed")
}

/// 视频收藏（独立于论坛收藏）
final class VideoFavoriteStore {

    static let shared = VideoFavoriteStore()

    private(set) var items: [VideoFavorite] = []
    private let storageKey = "fb_video_favorites_v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([VideoFavorite].self, from: data) {
            items = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }

    func isFavorited(url: String) -> Bool {
        return items.contains { $0.url == url }
    }

    func item(for url: String) -> VideoFavorite? {
        return items.first { $0.url == url }
    }

    @discardableResult
    func add(title: String, url: String, thumbnailURL: String? = nil) -> VideoFavorite {
        if let index = items.firstIndex(where: { $0.url == url }) {
            items[index].title = title
            if let thumbnailURL = thumbnailURL, !thumbnailURL.isEmpty {
                items[index].thumbnailURL = thumbnailURL
            }
            let item = items.remove(at: index)
            items.insert(item, at: 0)
            persist()
            return item
        }
        let item = VideoFavorite(id: UUID(),
                                 title: title,
                                 url: url,
                                 thumbnailURL: thumbnailURL,
                                 createdAt: Date())
        items.insert(item, at: 0)
        persist()
        return item
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    func removeAll() {
        items.removeAll()
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .videoFavoritesChanged, object: nil)
        }
    }
}
