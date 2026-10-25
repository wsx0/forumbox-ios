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
            setInterval(refresh, 4000);
        } catch (e) {}
    })();
    """

    /// 视频模式：让页面里的 video 支持内联播放（不强制全屏）
    static let videoEnhancer = """
    (function () {
        try {
            function fix(v) {
                try {
                    v.setAttribute('playsinline', '');
                    v.setAttribute('webkit-playsinline', '');
                    if (!v.controls) v.controls = true;
                } catch (e) {}
            }
            function scan() {
                var list = document.querySelectorAll('video');
                for (var i = 0; i < list.length; i++) fix(list[i]);
            }
            scan();
            setInterval(scan, 2500);
        } catch (e) {}
    })();
    """


    /// 视频模式：清理常见广告位 / 浮层 / 弹窗容器
    static let videoAdCleaner = """
    (function () {
        try {
            var selectors = [
                '.adsbygoogle', '[data-ad]', '[data-ad-slot]', '[data-ad-client]',
                '[id^="ad-"]', '[id*="-ad-"]', '[id$="-ad"]',
                '[class^="ad-"]', '[class*="-ad-"]', '[class$="-ad-"]',
                '.advertisement', '.advert', '.ad-container', '.ad-wrapper',
                '.ad-banner', '.ad-slot', '.popunder', '.popup-ad',
                '.sticky-ad', '.floating-ad', '.overlay-ad',
                '[class*="advert"]', '[id*="advert"]'
            ];
            function clean() {
                for (var i = 0; i < selectors.length; i++) {
                    var list = document.querySelectorAll(selectors[i]);
                    for (var j = 0; j < list.length; j++) {
                        try { list[j].remove(); } catch (e) {}
                    }
                }
            }
            clean();
            setInterval(clean, 2000);
        } catch (e) {}
    })();
    """
}
