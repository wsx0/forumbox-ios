(function () {
  try {
    var html = document.documentElement;
    if (html.getAttribute('data-fb-reader') === '1') return 'already';

    function textLength(el) {
      if (!el) return 0;
      var t = el.innerText || el.textContent || '';
      return t.replace(/\s+/g, ' ').trim().length;
    }

    function linkDensity(el) {
      var total = textLength(el);
      if (total <= 0) return 1;
      var links = el.querySelectorAll('a');
      var linkText = 0;
      for (var i = 0; i < links.length; i++) linkText += textLength(links[i]);
      if (linkText > total) linkText = total;
      return linkText / total;
    }

    var selectors = [
      '.postmessage', '.t_f', '.tpc_content', '.message', '.pct',
      '.article-content', '.post-content', '.entry-content', '.content-article',
      '[id^="postmessage_"]', 'article', 'main',
      '[class*="article"]', '[class*="post-content"]', '[class*="content"]'
    ];
    var candidates = [];
    for (var s = 0; s < selectors.length; s++) {
      var list = document.querySelectorAll(selectors[s]);
      for (var i = 0; i < list.length; i++) candidates.push(list[i]);
    }

    var best = null;
    var bestScore = 0;
    for (var c = 0; c < candidates.length; c++) {
      var el = candidates[c];
      var text = textLength(el);
      if (text < 160) continue;
      var score = text * (1 - linkDensity(el));
      if (score > bestScore) {
        bestScore = score;
        best = el;
      }
    }

    if (!best) {
      // 兜底：找包含最多文字段落的容器
      var ps = document.querySelectorAll('p');
      var totalP = 0;
      for (var p = 0; p < ps.length; p++) totalP += textLength(ps[p]);
      if (totalP < 200) return 'no-content';
      var bestP = 0;
      for (var q = 0; q < ps.length; q++) {
        var parent = ps[q].parentElement;
        if (!parent) continue;
        var t2 = textLength(parent);
        if (t2 > bestP) {
          bestP = t2;
          best = parent;
        }
      }
      if (!best) return 'no-content';
    }

    var clone = best.cloneNode(true);
    var drop = clone.querySelectorAll(
      'script, style, iframe, ins, noscript, nav, aside, form, button, input, select, textarea,' +
      '.ad, .ads, .advert, .adsbygoogle, [class*="advert"], [id*="advert"], [class*="adsbygoogle"]');
    for (var d = drop.length - 1; d >= 0; d--) {
      if (drop[d] && drop[d].parentNode) drop[d].parentNode.removeChild(drop[d]);
    }

    var imgs = clone.querySelectorAll('img');
    for (var m = 0; m < imgs.length; m++) {
      imgs[m].removeAttribute('width');
      imgs[m].removeAttribute('height');
      imgs[m].style.maxWidth = '100%';
      imgs[m].style.height = 'auto';
      imgs[m].style.borderRadius = '10px';
    }

    var titleText = (document.title || '').trim();

    var style = document.createElement('style');
    style.textContent =
      'html,body{background:#0b1220!important;color:#e5e7eb!important;margin:0!important;padding:0!important;}' +
      '#fb-reader{padding:18px 18px 56px;max-width:760px;margin:0 auto;' +
      'font-family:-apple-system,"PingFang SC","Microsoft YaHei UI",sans-serif;}' +
      '#fb-reader .fb-reader-title{font-size:23px;font-weight:700;line-height:1.5;margin:6px 0 10px;color:#fff;}' +
      '#fb-reader .fb-reader-meta{font-size:12px;color:#64748b;margin-bottom:20px;word-break:break-all;}' +
      '#fb-reader .fb-reader-body{font-size:17px;line-height:1.95;color:#dbe3f0;}' +
      '#fb-reader .fb-reader-body a{color:#7dd3fc;text-decoration:none;}' +
      '#fb-reader .fb-reader-body img,#fb-reader .fb-reader-body video{max-width:100%;height:auto;}' +
      '#fb-reader .fb-reader-body p{margin:0 0 1em;}' +
      '#fb-reader .fb-reader-body blockquote{margin:1em 0;padding:10px 16px;border-left:3px solid #38bdf8;' +
      'background:rgba(56,189,248,.08);border-radius:6px;color:#cbd5e1;}' +
      '#fb-reader .fb-reader-body pre{background:#0f172a;border:1px solid #1e2f4c;border-radius:8px;' +
      'padding:12px;overflow:auto;font-size:13px;}' +
      '#fb-reader .fb-reader-body table{max-width:100%;display:block;overflow:auto;}' +
      '#fb-reader .fb-reader-body h1,#fb-reader .fb-reader-body h2,#fb-reader .fb-reader-body h3{' +
      'color:#f1f5f9;line-height:1.5;margin:1.2em 0 .6em;}';
    document.head.appendChild(style);

    var wrap = document.createElement('div');
    wrap.id = 'fb-reader';

    var titleEl = document.createElement('div');
    titleEl.className = 'fb-reader-title';
    titleEl.textContent = titleText;

    var metaEl = document.createElement('div');
    metaEl.className = 'fb-reader-meta';
    metaEl.textContent = location.href;

    var bodyEl = document.createElement('div');
    bodyEl.className = 'fb-reader-body';
    bodyEl.appendChild(clone);

    wrap.appendChild(titleEl);
    wrap.appendChild(metaEl);
    wrap.appendChild(bodyEl);

    document.body.innerHTML = '';
    document.body.appendChild(wrap);
    html.setAttribute('data-fb-reader', '1');
    window.scrollTo(0, 0);
    return 'ok';
  } catch (e) {
    return 'error: ' + (e && e.message ? e.message : 'unknown');
  }
})();
