import Foundation

struct VideoSite: Codable, Equatable {
    var id: UUID
    var name: String
    var note: String
    var url: String
    var emoji: String

    init(id: UUID = UUID(),
         name: String,
         note: String,
         url: String,
         emoji: String) {
        self.id = id
        self.name = name
        self.note = note
        self.url = url
        self.emoji = emoji
    }
}

enum VideoSites {
    /// 视频 Tab 的默认站点
    static let defaults: [VideoSite] = [
        VideoSite(name: "Pornhub",
                  note: "cn.pornhub.com",
                  url: "https://cn.pornhub.com/",
                  emoji: "🔞"),
        VideoSite(name: "XVideos",
                  note: "www.xvideos.com",
                  url: "https://www.xvideos.com/",
                  emoji: "🎞️"),
        VideoSite(name: "Hsex",
                  note: "hsex.men",
                  url: "https://hsex.men/",
                  emoji: "🎬"),
        VideoSite(name: "Hiporn",
                  note: "hiporn.net",
                  url: "https://hiporn.net/",
                  emoji: "🔥"),
        VideoSite(name: "麻豆",
                  note: "madou.club",
                  url: "https://madou.club/",
                  emoji: "🎥"),
        VideoSite(name: "FullPorner",
                  note: "fullporner.com",
                  url: "https://fullporner.com/",
                  emoji: "🍑"),
        VideoSite(name: "TubeBDSM",
                  note: "tubebdsm.com",
                  url: "https://www.tubebdsm.com/zh/?ref=porndude",
                  emoji: "⛓️")
    ]
}

extension Notification.Name {
    static let videoSitesChanged = Notification.Name("fb_video_sites_changed")
}

/// 视频站点存储（用户可增删改）
final class VideoSiteStore {

    static let shared = VideoSiteStore()

    private(set) var sites: [VideoSite] = []
    private let storageKey = "fb_video_sites_v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([VideoSite].self, from: data) {
            sites = decoded
        } else {
            sites = VideoSites.defaults
        }
    }

    @discardableResult
    func add(name: String, note: String, url: String, emoji: String = "🎬") -> VideoSite {
        let site = VideoSite(name: name, note: note, url: url, emoji: emoji)
        sites.append(site)
        persist()
        return site
    }

    func update(id: UUID, name: String, note: String, url: String, emoji: String) {
        guard let index = sites.firstIndex(where: { $0.id == id }) else { return }
        sites[index].name = name
        sites[index].note = note
        sites[index].url = url
        sites[index].emoji = emoji
        persist()
    }

    func remove(id: UUID) {
        sites.removeAll { $0.id == id }
        persist()
    }

    func resetDefaults() {
        sites = VideoSites.defaults
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(sites) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .videoSitesChanged, object: nil)
        }
    }
}
