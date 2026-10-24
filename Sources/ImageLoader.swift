import UIKit
import WebKit

/// 帖子缩略图异步加载
/// 论坛的图片地址带 JS 反爬校验，必须带上 WKWebView 里的 cookie 才会返回真实图片
final class ImageLoader {

    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession
    private var cookies: [(name: String, value: String, domain: String)] = []
    private var lastCookieRefresh = Date.distantPast
    private let cookieRefreshInterval: TimeInterval = 20

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 20
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
        cache.countLimit = 300
    }

    /// 从 WebView 的 cookie 仓库同步 cookie（图片反爬需要）
    func refreshCookies(force: Bool = false) {
        guard force || Date().timeIntervalSince(lastCookieRefresh) > cookieRefreshInterval else { return }
        lastCookieRefresh = Date()
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
            let list = cookies.map { (name: $0.name, value: $0.value, domain: $0.domain) }
            DispatchQueue.main.async {
                self?.cookies = list
            }
        }
    }

    private func cookieHeader(for host: String) -> String? {
        guard !host.isEmpty else { return nil }
        let matched = cookies.filter { cookie in
            let domain = cookie.domain.hasPrefix(".") ? String(cookie.domain.dropFirst()) : cookie.domain
            return !domain.isEmpty && (host == domain || host.hasSuffix("." + domain))
        }
        guard !matched.isEmpty else { return nil }
        return matched.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
    }

    @discardableResult
    func load(_ urlString: String,
              referer: String?,
              completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        guard !urlString.isEmpty else {
            completion(nil)
            return nil
        }
        if let cached = cache.object(forKey: urlString as NSString) {
            completion(cached)
            return nil
        }
        guard let url = URL(string: urlString) else {
            completion(nil)
            return nil
        }

        refreshCookies()

        var request = URLRequest(url: url)
        request.setValue(UserAgents.mobileSafari, forHTTPHeaderField: "User-Agent")
        request.setValue("image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
                         forHTTPHeaderField: "Accept")
        request.setValue("zh-CN,zh;q=0.9", forHTTPHeaderField: "Accept-Language")
        if let cookieHeader = cookieHeader(for: url.host ?? "") {
            request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
        if let referer = referer, let refererURL = URL(string: referer),
           let scheme = refererURL.scheme, let host = refererURL.host {
            request.setValue("\(scheme)://\(host)/", forHTTPHeaderField: "Referer")
        }

        let task = session.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data,
                  let image = UIImage(data: data),
                  image.size.width > 10 else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self?.cache.setObject(image, forKey: urlString as NSString)
            DispatchQueue.main.async { completion(image) }
        }
        task.resume()
        return task
    }
}
