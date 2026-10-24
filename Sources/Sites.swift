import Foundation

struct Site: Codable, Equatable {
    let name: String
    let note: String
    let url: String
    /// 站内搜索页地址（nil 表示该站没有可用的站内搜索）
    let searchURL: String?
    /// 列表里的 emoji 小图标
    let emoji: String

    init(name: String,
         note: String,
         url: String,
         searchURL: String? = nil,
         emoji: String = "🌐") {
        self.name = name
        self.note = note
        self.url = url
        self.searchURL = searchURL
        self.emoji = emoji
    }
}

enum Sites {
    /// 首次安装时的默认站点
    static let defaults: [Site] = [
        Site(name: "98堂",
             note: "Discuz! · 综合论坛",
             url: "https://sehuatang.net/forum.php?forumlist=1&mobile=2",
             searchURL: "https://sehuatang.net/search.php?mod=forum&mobile=2",
             emoji: "🌸"),
        Site(name: "司机社",
             note: "Discuz! · 热门导读",
             url: "https://xsijishe.net/forum.php?mod=guide&view=hot&mobile=2&forcemobile=1",
             searchURL: "https://xsijishe.net/search.php?mod=forum&mobile=2&forcemobile=1",
             emoji: "🚗"),
        Site(name: "JavBus 论坛",
             note: "论坛 · 搜索入口",
             url: "https://www.javbus.com/forum/search.php",
             searchURL: "https://www.javbus.com/forum/search.php",
             emoji: "🚌"),
        Site(name: "南+ South Plus",
             note: "phpwind · 轻量版",
             url: "https://www.south-plus.net/simple/",
             searchURL: "https://www.south-plus.net/search.php",
             emoji: "🌿"),
        Site(name: "爱看妹",
             note: "资源页",
             url: "https://aikanmei.com/fuli-content/A5Tn1d/index.html",
             emoji: "👀"),
        Site(name: "x999x",
             note: "Discuz! · 论坛",
             url: "https://www.x999x.me/forum.php",
             searchURL: "https://www.x999x.me/search.php?mod=forum&mobile=2",
             emoji: "🎴"),
        Site(name: "Pornolab",
             note: "国外论坛",
             url: "http://pornolab.net/forum/index.php",
             searchURL: "http://pornolab.net/forum/search.php",
             emoji: "🌍")
    ]

    /// 当前站点列表（跟随 SiteStore，可在 App 内增删改）
    static var all: [Site] {
        return SiteStore.shared.sites
    }
}

/// 站点列表存储（UserDefaults JSON）
final class SiteStore {

    static let shared = SiteStore()

    private let storageKey = "fb_sites_v1"
    private(set) var sites: [Site] = []

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Site].self, from: data),
           !decoded.isEmpty {
            // 旧版本 JSON 里多余的字段会被自动忽略
            sites = decoded
        } else {
            sites = Sites.defaults
        }
    }

    func add(_ site: Site) {
        sites.append(site)
        persist()
    }

    func replace(at index: Int, with site: Site) {
        guard sites.indices.contains(index) else { return }
        sites[index] = site
        persist()
    }

    func remove(at index: Int) {
        guard sites.indices.contains(index) else { return }
        sites.remove(at: index)
        persist()
    }

    func move(from source: Int, to destination: Int) {
        guard sites.indices.contains(source) else { return }
        let item = sites.remove(at: source)
        let target = min(max(destination, 0), sites.count)
        sites.insert(item, at: target)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(sites) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .sitesChanged, object: nil)
        }
    }
}
