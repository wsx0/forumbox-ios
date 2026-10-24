import Foundation

struct FavoriteFolder: Codable, Equatable {
    let id: UUID
    var name: String
    let createdAt: Date
}

struct FavoriteItem: Codable, Equatable {
    let id: UUID
    let title: String
    let url: String
    let siteName: String
    let siteEmoji: String
    var folderId: UUID?
    let createdAt: Date
}

/// 收藏与收藏夹存储（UserDefaults JSON）
final class FavoriteStore {

    static let shared = FavoriteStore()

    private(set) var folders: [FavoriteFolder] = []
    private(set) var items: [FavoriteItem] = []

    private let foldersKey = "fb_fav_folders_v1"
    private let itemsKey = "fb_fav_items_v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: foldersKey),
           let decoded = try? JSONDecoder().decode([FavoriteFolder].self, from: data) {
            folders = decoded
        }
        if let data = UserDefaults.standard.data(forKey: itemsKey),
           let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) {
            items = decoded
        }
    }

    // MARK: - 查询

    func items(in folderId: UUID?) -> [FavoriteItem] {
        return items.filter { $0.folderId == folderId }.sorted { $0.createdAt > $1.createdAt }
    }

    func allItemsSorted() -> [FavoriteItem] {
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func count(in folderId: UUID?) -> Int {
        return items.filter { $0.folderId == folderId }.count
    }

    func isFavorited(url: String) -> Bool {
        return items.contains { $0.url == url }
    }

    func item(for url: String) -> FavoriteItem? {
        return items.first { $0.url == url }
    }

    func folderName(for folderId: UUID?) -> String {
        guard let folderId = folderId else { return "未分类" }
        return folders.first { $0.id == folderId }?.name ?? "未分类"
    }

    // MARK: - 收藏

    @discardableResult
    func add(title: String,
             url: String,
             siteName: String,
             siteEmoji: String,
             folderId: UUID?) -> FavoriteItem {
        let item = FavoriteItem(id: UUID(),
                                title: title,
                                url: url,
                                siteName: siteName,
                                siteEmoji: siteEmoji,
                                folderId: folderId,
                                createdAt: Date())
        items.append(item)
        persist()
        return item
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    func remove(url: String) {
        items.removeAll { $0.url == url }
        persist()
    }

    func move(id: UUID, to folderId: UUID?) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].folderId = folderId
        persist()
    }

    // MARK: - 收藏夹

    @discardableResult
    func addFolder(name: String) -> FavoriteFolder {
        let folder = FavoriteFolder(id: UUID(), name: name, createdAt: Date())
        folders.append(folder)
        persist()
        return folder
    }

    func renameFolder(id: UUID, name: String) {
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        folders[index].name = name
        persist()
    }

    /// 删除收藏夹（夹内收藏移到「未分类」）
    func deleteFolder(id: UUID) {
        folders.removeAll { $0.id == id }
        for index in items.indices where items[index].folderId == id {
            items[index].folderId = nil
        }
        persist()
    }

    // MARK: - 持久化

    private func persist() {
        if let data = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(data, forKey: foldersKey)
        }
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: itemsKey)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .favoritesChanged, object: nil)
        }
    }
}
