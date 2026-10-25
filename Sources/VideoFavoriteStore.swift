import Foundation

struct VideoFavoriteFolder: Codable, Equatable {
    let id: UUID
    var name: String
    let createdAt: Date
}

struct VideoFavorite: Codable, Equatable {
    let id: UUID
    var title: String
    let url: String
    var thumbnailURL: String?
    var folderId: UUID?
    var createdAt: Date
}

extension Notification.Name {
    static let videoFavoritesChanged = Notification.Name("fb_video_favorites_changed")
}

/// 视频收藏与视频收藏夹（独立于论坛收藏）
final class VideoFavoriteStore {

    static let shared = VideoFavoriteStore()

    private(set) var folders: [VideoFavoriteFolder] = []
    private(set) var items: [VideoFavorite] = []

    private let foldersKey = "fb_video_favorite_folders_v1"
    private let itemsKey = "fb_video_favorites_v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: foldersKey),
           let decoded = try? JSONDecoder().decode([VideoFavoriteFolder].self, from: data) {
            folders = decoded
        }
        if let data = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([VideoFavorite].self, from: data) {
            items = decoded.sorted { $0.createdAt > $1.createdAt }
        }

        // 旧版视频收藏没有收藏夹：统一迁移到「默认收藏夹」
        if items.contains(where: { $0.folderId == nil }) {
            let name = "默认收藏夹"
            let folder: VideoFavoriteFolder
            if let existing = folders.first(where: { $0.name == name }) {
                folder = existing
            } else {
                folder = VideoFavoriteFolder(id: UUID(), name: name, createdAt: Date())
                folders.append(folder)
            }
            for index in items.indices where items[index].folderId == nil {
                items[index].folderId = folder.id
            }
            persist()
        }
    }

    // MARK: - 查询

    func items(in folderId: UUID?) -> [VideoFavorite] {
        return items.filter { $0.folderId == folderId }.sorted { $0.createdAt > $1.createdAt }
    }

    func count(in folderId: UUID?) -> Int {
        return items.filter { $0.folderId == folderId }.count
    }

    func isFavorited(url: String) -> Bool {
        return items.contains { $0.url == url }
    }

    func item(for url: String) -> VideoFavorite? {
        return items.first { $0.url == url }
    }

    // MARK: - 收藏

    @discardableResult
    func add(title: String,
             url: String,
             thumbnailURL: String? = nil,
             folderId: UUID? = nil) -> VideoFavorite {
        if let index = items.firstIndex(where: { $0.url == url }) {
            items[index].title = title
            if let thumbnailURL = thumbnailURL, !thumbnailURL.isEmpty {
                items[index].thumbnailURL = thumbnailURL
            }
            if let folderId = folderId {
                items[index].folderId = folderId
            }
            items[index].createdAt = Date()
            let item = items.remove(at: index)
            items.insert(item, at: 0)
            persist()
            return item
        }
        let item = VideoFavorite(id: UUID(),
                                 title: title,
                                 url: url,
                                 thumbnailURL: thumbnailURL,
                                 folderId: folderId,
                                 createdAt: Date())
        items.insert(item, at: 0)
        persist()
        return item
    }

    func updateMetadata(url: String, title: String, thumbnailURL: String?) {
        guard let index = items.firstIndex(where: { $0.url == url }) else { return }
        if !title.isEmpty {
            items[index].title = title
        }
        if let thumbnailURL = thumbnailURL, !thumbnailURL.isEmpty {
            items[index].thumbnailURL = thumbnailURL
        }
        persist()
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    func move(id: UUID, to folderId: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].folderId = folderId
        persist()
    }

    // MARK: - 收藏夹

    @discardableResult
    func addFolder(name: String) -> VideoFavoriteFolder {
        let folder = VideoFavoriteFolder(id: UUID(), name: name, createdAt: Date())
        folders.append(folder)
        persist()
        return folder
    }

    func renameFolder(id: UUID, name: String) {
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[index].name = name
        persist()
    }

    /// 删除视频收藏夹（夹内视频一并删除）
    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
        items.removeAll { $0.folderId == id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(data, forKey: foldersKey)
        }
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemsKey)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .videoFavoritesChanged, object: nil)
        }
    }
}
