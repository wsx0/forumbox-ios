import Foundation

/// 注入到 WKWebView 的 JS 脚本（注入/抓取共用）
enum WebScripts {

    /// 屏蔽 JS 弹窗
    static let popupSuppressor = """
    (function () {
        try {
            window.open = function () { return null; };
        } catch (e) {}
    })();
    """

    /// 跳到站内搜索页后，自动填写关键词并提交
    static let autoSearch = """
    (function () {
        try {
            var hash = location.hash || '';
            var idx = hash.indexOf('fbq=');
            if (idx < 0) return;
            var raw = hash.substring(idx + 4);
            var q = '';
            try { q = decodeURIComponent(raw); } catch (e) { q = raw; }
            if (!q) return;
            var inputs = document.querySelectorAll('input[type="text"], input[type="search"], input:not([type])');
            var target = null;
            for (var i = 0; i < inputs.length; i++) {
                var inp = inputs[i];
                var name = (inp.name || '') + ' ' + (inp.id || '') + ' ' + (inp.placeholder || '');
                if (/srchtxt|keyword|search|搜索/i.test(name)) { target = inp; break; }
            }
            if (!target) return;
            target.value = q;
            target.dispatchEvent(new Event('input', { bubbles: true }));
            target.dispatchEvent(new Event('change', { bubbles: true }));
            var form = target.form;
            if (form) {
                var btn = form.querySelector('button[type="submit"], input[type="submit"], button');
                if (btn) { btn.click(); return; }
                form.submit();
                return;
            }
            var ev = new KeyboardEvent('keydown', { key: 'Enter', keyCode: 13, which: 13, bubbles: true });
            target.dispatchEvent(ev);
        } catch (e) {}
    })();
    """

    /// 从搜索结果页提取「帖子链接 + 标题 + 缩略图」，返回 JSON 字符串
    static let extractResults = """
    (function () {
        try {
            var out = [];
            var seen = {};
            var anchors = document.querySelectorAll('a[href]');
            var threadPattern = /(thread-|viewthread|viewtopic|read\\.php\\?tid=|forum\\.php\\?mod=viewthread|\\/thread\\/|\\/topic\\/)/i;

            function absoluteURL(raw) {
                if (!raw) return '';
                raw = ('' + raw).trim();
                if (!raw || raw.indexOf('data:') === 0) return '';
                try { return new URL(raw, location.href).href; } catch (e) { return ''; }
            }

            function isBadImage(src, cls) {
                return /avatar|head|icon|emoji|smiley|badge/i.test(src + ' ' + cls);
            }

            function findThumb(anchor) {
                var node = anchor;
                for (var depth = 0; depth < 6 && node; depth++) {
                    var imgs = node.querySelectorAll ? node.querySelectorAll('img') : [];
                    for (var i = 0; i < imgs.length; i++) {
                        var img = imgs[i];
                        var attrs = [img.getAttribute('data-original'),
                                     img.getAttribute('data-src'),
                                     img.getAttribute('data-lazy'),
                                     img.getAttribute('data-echo'),
                                     img.getAttribute('src'),
                                     img.currentSrc];
                        for (var k = 0; k < attrs.length; k++) {
                            var src = absoluteURL(attrs[k]);
                            if (!src) continue;
                            var cls = (img.className || '') + ' ' + (img.id || '');
                            if (isBadImage(src, cls)) continue;
                            var w = parseInt(img.getAttribute('width') || '0', 10) || img.naturalWidth || 0;
                            var h = parseInt(img.getAttribute('height') || '0', 10) || img.naturalHeight || 0;
                            if (w > 0 && w < 40) continue;
                            if (h > 0 && h < 30) continue;
                            return src;
                        }
                    }

                    var all = node.querySelectorAll ? node.querySelectorAll('*') : [];
                    for (var j = 0; j < all.length; j++) {
                        var el = all[j];
                        var style = el.getAttribute ? (el.getAttribute('style') || '') : '';
                        var at = style.indexOf('url(');
                        if (at < 0) continue;
                        var rest = style.substring(at + 4);
                        var end = rest.indexOf(')');
                        if (end < 0) continue;
                        var raw = rest.substring(0, end).split('"').join('').split("'").join('').trim();
                        var bg = absoluteURL(raw);
                        if (bg && !isBadImage(bg, '')) return bg;
                    }

                    if (node.tagName === 'LI' || node.tagName === 'TR') break;
                    node = node.parentElement;
                }
                return '';
            }

            for (var i = 0; i < anchors.length; i++) {
                var a = anchors[i];
                var href = a.href || '';
                if (!href) continue;
                if (href.indexOf('javascript:') === 0) continue;
                if (!threadPattern.test(href)) continue;
                var text = (a.innerText || a.textContent || '').replace(/\\s+/g, ' ').trim();
                if (text.length < 4 || text.length > 120) continue;
                var key = href.split('#')[0];
                if (seen[key]) continue;
                seen[key] = true;
                out.push({ title: text, url: key, thumb: findThumb(a) });
                if (out.length >= 20) break;
            }
            return JSON.stringify(out);
        } catch (e) {
            return '[]';
        }
    })();
    """
}
