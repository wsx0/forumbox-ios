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

    /// 页面里出现 ED2K 链接时，显示一个「ED2K → 115」悬浮按钮
    static let ed2kScanner = """
    (function () {
        try {
            if (window.__fbEd2kInstalled) return;
            window.__fbEd2kInstalled = true;
            function refresh() {
                var links = document.querySelectorAll('a[href^="ed2k://"], a[href^="ED2K://"], a[href^="Ed2k://"]');
                var btn = document.getElementById('fb-ed2k-btn');
                if (!links.length) {
                    if (btn) btn.remove();
                    return;
                }
                if (!btn) {
                    btn = document.createElement('div');
                    btn.id = 'fb-ed2k-btn';
                    btn.style.cssText = 'position:fixed;right:14px;bottom:84px;z-index:2147483647;background:#ff6fa5;color:#fff;font:600 13px -apple-system,BlinkMacSystemFont,sans-serif;padding:9px 14px;border-radius:19px;box-shadow:0 6px 18px rgba(0,0,0,.28);';
                    btn.addEventListener('click', function () {
                        var out = [];
                        var els = document.querySelectorAll('a[href^="ed2k://"], a[href^="ED2K://"], a[href^="Ed2k://"]');
                        for (var i = 0; i < els.length && i < 20; i++) {
                            out.push(els[i].href);
                        }
                        try { window.webkit.messageHandlers.ed2k.postMessage({ links: out }); } catch (e) {}
                    });
                    document.body.appendChild(btn);
                }
                btn.textContent = 'ED2K · ' + links.length + ' → 115';
            }
            refresh();
            setInterval(refresh, 2500);
        } catch (e) {}
    })();
    """
}
