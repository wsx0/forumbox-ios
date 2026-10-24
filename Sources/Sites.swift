import Foundation

struct Site {
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
    static let all: [Site] = [
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
             searchURL: nil,
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
}
