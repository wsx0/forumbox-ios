import UIKit

/// 轻量异常记录：崩溃后下次启动可复制异常信息
enum CrashLogger {

    private static var directory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private static var crashURL: URL {
        return directory.appendingPathComponent("fb_last_crash.txt")
    }

    private static var actionURL: URL {
        return directory.appendingPathComponent("fb_last_action.txt")
    }

    static func install() {
        NSSetUncaughtExceptionHandler { exception in
            let text = """
            \(Date())
            \(exception.name.rawValue)
            \(exception.reason ?? "")
            \(exception.callStackSymbols.joined(separator: "\n"))
            """
            try? text.write(to: crashURL, atomically: true, encoding: .utf8)
        }
    }

    static func log(_ message: String) {
        let text = "\(Date())\n\(message)\n"
        try? text.write(to: actionURL, atomically: true, encoding: .utf8)
    }

    static func presentIfNeeded(from viewController: UIViewController?) {
        guard let viewController = viewController else { return }
        guard let crash = try? String(contentsOf: crashURL, encoding: .utf8), !crash.isEmpty else {
            return
        }
        let action = (try? String(contentsOf: actionURL, encoding: .utf8)) ?? ""
        let detail = String((crash + "\n\n最后操作：\n" + action).prefix(1200))
        let alert = UIAlertController(title: "上次异常记录",
                                      message: detail,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "复制", style: .default) { _ in
            UIPasteboard.general.string = crash + "\n" + action
            try? FileManager.default.removeItem(at: crashURL)
        })
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in
            try? FileManager.default.removeItem(at: crashURL)
            try? FileManager.default.removeItem(at: actionURL)
        })
        viewController.present(alert, animated: true)
    }
}
