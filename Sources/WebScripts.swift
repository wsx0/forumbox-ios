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


    /// 视频模式：清理广告位 / 浮层 / 弹窗 / 跳过按钮
    static let videoAdCleaner = """
    (function () {
        try {
            var selectors = [
                '.adsbygoogle', '[data-ad]', '[data-ad-slot]', '[data-ad-client]', '[data-advertisement]',
                '[id^="ad-"]', '[id*="-ad-"]', '[id$="-ad"]', '[id="ad"]', '[id="ads"]',
                '[class^="ad-"]', '[class*="-ad-"]', '[class$="-ad"]',
                '.ad', '.ads', '.advertisement', '.advert',
                '.ad-container', '.ad-wrapper', '.ad-banner', '.ad-slot', '.ad-box',
                '.ad-block', '.ad-zone', '.ad-area', '.ad-placeholder', '.ad-space',
                '.ad-unit', '.ad-holder', '.ad-frame', '.ad-content', '.ad-label',
                '.ad-overlay', '.ad-float', '.ad-sticky', '.ad-popup', '.ad-modal',
                '.video-ad', '.preroll', '.midroll',
                '.popunder', '.popup-ad', '.sticky-ad', '.floating-ad', '.overlay-ad',
                '[class*="advert"]', '[id*="advert"]', '[class*="popunder"]', '[id*="popunder"]',
                '[class*="sponsor-ad"]'
            ];
            var adHosts = [
                'exoclick.com', 'exosrv.com', 'juicyads.com', 'juicyads.net',
                'trafficjunky.net', 'trafficjunky.com', 'trafficstars.com',
                'exdynsrv.com', 'magsrv.com', 'bngprm.com', 'adsco.re', 'prpnads.com',
                'popads.net', 'popcash.net', 'clickadu.com', 'propellerads.com',
                'adsterra.com', 'hilltopads.net', 'tsyndicate.com', 'realsrv.com',
                'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
                'adnxs.com', 'taboola.com', 'outbrain.com', 'mgid.com'
            ];
            var skipWords = ['跳过广告', '跳过', 'skipad', 'skip'];
            function ensureCSS() {
                if (document.getElementById('fb-ad-css')) return;
                var style = document.createElement('style');
                style.id = 'fb-ad-css';
                style.type = 'text/css';
                style.appendChild(document.createTextNode(selectors.join(',') + '{display:none !important;}'));
                (document.head || document.documentElement).appendChild(style);
            }
            function isAdHref(href) {
                if (!href) return false;
                for (var i = 0; i < adHosts.length; i++) {
                    if (href.indexOf(adHosts[i]) >= 0) return true;
                }
                return false;
            }
            function clean() {
                ensureCSS();
                for (var i = 0; i < selectors.length; i++) {
                    var list = document.querySelectorAll(selectors[i]);
                    for (var j = 0; j < list.length; j++) {
                        try { list[j].remove(); } catch (e) {}
                    }
                }
                var links = document.querySelectorAll('a[href]');
                for (var k = 0; k < links.length; k++) {
                    try {
                        if (isAdHref(links[k].href)) links[k].remove();
                    } catch (e) {}
                }
                var frames = document.querySelectorAll('iframe[src]');
                for (var f = 0; f < frames.length; f++) {
                    try {
                        if (isAdHref(frames[f].src)) frames[f].remove();
                    } catch (e) {}
                }
                var nodes = document.querySelectorAll('button,a,div,span');
                for (var n = 0; n < nodes.length; n++) {
                    try {
                        var text = (nodes[n].textContent || '').replace(/ /g, '').trim().toLowerCase();
                        if (skipWords.indexOf(text) >= 0) nodes[n].click();
                    } catch (e) {}
                }
            }
            clean();
            setInterval(clean, 1500);
        } catch (e) {}
    })();
    """

    /// 视频模式：提取页面真实标题与缩略图（og:title / og:image / video poster）
    static let videoMetadata = """
    (function () {
        try {
            function meta(selector) {
                var el = document.querySelector(selector);
                if (!el) return '';
                return (el.content || el.href || el.src || '').trim();
            }
            function absolute(value) {
                if (!value) return '';
                try { return new URL(value, location.href).href; } catch (e) { return value; }
            }
            var title = meta('meta[property="og:title"]')
                || meta('meta[name="twitter:title"]')
                || meta('meta[name="title"]')
                || meta('meta[itemprop="name"]')
                || (document.querySelector('h1') ? document.querySelector('h1').textContent.trim() : '')
                || document.title
                || '';
            var image = meta('meta[property="og:image"]')
                || meta('meta[property="og:image:url"]')
                || meta('meta[property="og:image:secure_url"]')
                || meta('meta[name="twitter:image"]')
                || meta('meta[name="twitter:image:src"]')
                || meta('meta[name="thumbnail"]')
                || meta('link[rel="image_src"]')
                || meta('meta[itemprop="thumbnailUrl"]');
            if (!image) {
                var video = document.querySelector('video[poster]');
                if (video && video.poster) image = video.poster;
            }
            return { title: title, image: absolute(image) };
        } catch (e) {
            return { title: document.title || '', image: '' };
        }
    })();
    """


    /// 视频模式：当前清晰度 / 倍速 / 可切换的 source
    static let videoPlaybackInfo = """
    (function () {
        try {
            var v = document.querySelector('video');
            if (!v) return { height: 0, width: 0, rate: 1, qualities: [] };
            var qualities = [];
            var seen = {};
            var sources = v.querySelectorAll('source');
            for (var i = 0; i < sources.length; i++) {
                var source = sources[i];
                var label = (source.label || (source.dataset && source.dataset.label)
                    || (source.dataset && source.dataset.quality)
                    || (source.dataset && source.dataset.resolution) || '').trim();
                var src = source.src || '';
                if (!label) {
                    var match = src.match(/(\\d{3,4})[pP]/);
                    if (match) label = match[1] + 'P';
                }
                if (!label || seen[label]) continue;
                seen[label] = 1;
                qualities.push({ label: label, index: i });
            }
            return {
                height: v.videoHeight || 0,
                width: v.videoWidth || 0,
                rate: v.playbackRate || 1,
                qualities: qualities
            };
        } catch (e) {
            return { height: 0, width: 0, rate: 1, qualities: [] };
        }
    })();
    """


    /// 全站广告样式：文档开始时挂 CSS，先隐藏再清理
    static let adBlockCSS = """
    (function () {
        try {
            if (document.getElementById('fb-ad-css')) return;
            var selectors = [
                '.adsbygoogle', '[data-ad]', '[data-ad-slot]', '[data-ad-client]', '[data-advertisement]',
                '[id^="ad-"]', '[id*="-ad-"]', '[id$="-ad"]', '[id="ad"]', '[id="ads"]',
                '[class^="ad-"]', '[class*="-ad-"]', '[class$="-ad"]',
                '.ad', '.ads', '.advertisement', '.advert',
                '.ad-container', '.ad-wrapper', '.ad-banner', '.ad-slot', '.ad-box',
                '.ad-block', '.ad-zone', '.ad-area', '.ad-placeholder', '.ad-space',
                '.ad-unit', '.ad-holder', '.ad-frame', '.ad-content', '.ad-label',
                '.ad-overlay', '.ad-float', '.ad-sticky', '.ad-popup', '.ad-modal',
                '.video-ad', '.preroll', '.midroll',
                '.popunder', '.popup-ad', '.sticky-ad', '.floating-ad', '.overlay-ad',
                '[class*="advert"]', '[id*="advert"]', '[class*="popunder"]', '[id*="popunder"]',
                '[class*="sponsor-ad"]'
            ];
            var css = selectors.join(',') + '{display:none !important;}';
            var style = document.createElement('style');
            style.id = 'fb-ad-css';
            style.type = 'text/css';
            style.appendChild(document.createTextNode(css));
            (document.head || document.documentElement).appendChild(style);
        } catch (e) {}
    })();
    """
}
