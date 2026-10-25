import UIKit
import WebKit

enum Cloud115Error: Error {
    case notLoggedIn
    case failed(String)
}

/// 115 网盘：用 App 内网页的登录 cookie 调用「云下载」接口，把 ED2K 链接加进去
final class Cloud115 {

    static let shared = Cloud115()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        session = URLSession(configuration: config)
    }

    func addED2K(_ link: String, completion: @escaping (Result<Void, Cloud115Error>) -> Void) {
        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            let matched = cookies.filter { cookie in
                let domain = cookie.domain.hasPrefix(".") ? String(cookie.domain.dropFirst()) : cookie.domain
                return domain == "115.com" || domain.hasSuffix(".115.com")
            }
            let header = matched.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            guard !header.isEmpty else {
                DispatchQueue.main.async { completion(.failure(.notLoggedIn)) }
                return
            }

            guard let url = URL(string: "https://115.com/web/lixian/?ct=lixian&ac=add_task_url") else {
                DispatchQueue.main.async { completion(.failure(.failed("接口地址无效"))) }
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded; charset=UTF-8",
                             forHTTPHeaderField: "Content-Type")
            request.setValue("https://115.com/", forHTTPHeaderField: "Referer")
            request.setValue("https://115.com", forHTTPHeaderField: "Origin")
            request.setValue(UserAgents.mobileSafari, forHTTPHeaderField: "User-Agent")
            request.setValue(header, forHTTPHeaderField: "Cookie")

            let encoded = link.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            request.httpBody = "url=\(encoded)".data(using: .utf8)

            self.session.dataTask(with: request) { data, _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(.failed(error.localizedDescription)))
                        return
                    }
                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        completion(.failure(.failed("115 返回内容无法识别")))
                        return
                    }
                    if (json["state"] as? Bool) == true {
                        completion(.success(()))
                        return
                    }
                    let message = (json["error_msg"] as? String) ?? "添加失败"
                    if message.contains("登录") || message.contains("验证") {
                        completion(.failure(.notLoggedIn))
                    } else {
                        completion(.failure(.failed(message)))
                    }
                }
            }.resume()
        }
    }
}
