import Foundation

/// 注入到 WKWebView 的 JS 脚本
enum WebScripts {

    /// 屏蔽 JS 弹窗
    static let popupSuppressor = """
    (function () {
        try {
            window.open = function () { return null; };
        } catch (e) {}
    })();
    """
}
