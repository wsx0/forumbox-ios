import UIKit

/// 帖子缩略图异步加载（内存缓存 + 带 Referer，避免防盗链）
final class ImageLoader {

    static let shared = ImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 20
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)
        cache.countLimit = 300
    }

    func load(_ urlString: String, referer: String?, completion: @escaping (UIImage?) -> Void) {
        guard !urlString.isEmpty else {
            completion(nil)
            return
        }
        if let cached = cache.object(forKey: urlString as NSString) {
            completion(cached)
            return
        }
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue(UserAgents.mobileSafari, forHTTPHeaderField: "User-Agent")
        if let referer = referer, let refererURL = URL(string: referer),
           let scheme = refererURL.scheme, let host = refererURL.host {
            request.setValue("\(scheme)://\(host)/", forHTTPHeaderField: "Referer")
        }

        session.dataTask(with: request) { [weak self] data, _, _ in
            guard let data = data,
                  let image = UIImage(data: data),
                  image.size.width > 10 else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            self?.cache.setObject(image, forKey: urlString as NSString)
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }
}
