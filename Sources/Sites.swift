import Foundation

struct Site {
    let name: String
    let note: String
    let url: String
}

enum Sites {
    static let all: [Site] = [
        Site(name: "98堂", note: "Discuz! · 综合论坛", url: "https://sehuatang.net/forum.php?forumlist=1&mobile=2"),
        Site(name: "司机社", note: "Discuz! · 热门导读", url: "https://xsijishe.net/forum.php?mod=guide&view=hot&mobile=2&forcemobile=1"),
        Site(name: "JavBus 论坛", note: "论坛 · 搜索入口", url: "https://www.javbus.com/forum/search.php"),
        Site(name: "南+ South Plus", note: "phpwind · 轻量版", url: "https://www.south-plus.net/simple/"),
        Site(name: "爱看妹", note: "资源页", url: "https://aikanmei.com/fuli-content/A5Tn1d/index.html"),
        Site(name: "x999x", note: "Discuz! · 论坛", url: "https://www.x999x.me/forum.php"),
        Site(name: "Pornolab", note: "国外论坛", url: "http://pornolab.net/forum/index.php")
    ]
}
