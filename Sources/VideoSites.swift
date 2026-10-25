import Foundation

struct VideoSite {
    let name: String
    let note: String
    let url: String
    let emoji: String
}

enum VideoSites {
    /// 视频 Tab 的默认站点
    static let all: [VideoSite] = [
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
