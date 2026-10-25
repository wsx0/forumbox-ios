import UIKit

/// 轻量异常/最后操作记录：崩溃后下次启动可复制诊断信息
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

    private static var cleanURL: URL {
        return directory.appendingPathComponent("fb_session_clean.txt")
    }

    /// 安装未捕获异常处理器
    static func install() {
        NSSetUncaughtExceptionHandler(handleUncaughtException)
    }

    /// 启动时调用：返回「上次会话未正常结束」时的最后操作
    static func beginSession() -> String? {
        let wasClean = FileManager.default.fileExists(atPath: cleanURL.path)
        try? FileManager.default.removeItem(at: cleanURL)
        guard !wasClean else { return nil }
        let action = (try? String(contentsOf: actionURL, encoding: .utf8)) ?? ""
        return action.isEmpty ? nil : action
    }

    /// App 正常进入后台/退出时调用
    static func markClean() {
        try? "clean".write(to: cleanURL, atomically: true, encoding: .utf8)
    }

    static func log(_ message: String) {
        let text = "\(Date())\n\(message)\n"
        try? text.write(to: actionURL, atomically: true, encoding: .utf8)
    }

    static func presentIfNeeded(from viewController: UIViewController?, previousAction: String?) {
        guard let viewController = viewController else { return }
        guard let crash = try? String(contentsOf: crashURL, encoding: .utf8), !crash.isEmpty else {
            return
        }
        let action = previousAction ?? ((try? String(contentsOf: actionURL, encoding: .utf8)) ?? "")
        let detail = String((crash + "\n\n最后操作：\n" + action).prefix(1400))
        let alert = UIAlertController(title: "上次异常记录",
                                      message: detail,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "复制", style: .default) { _ in
            UIPasteboard.general.string = crash + "\n" + action
            CrashLogger.clearDiagnostics()
        })
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in
            CrashLogger.clearDiagnostics()
        })
        viewController.present(alert, animated: true)
    }

    private static func clearDiagnostics() {
        try? FileManager.default.removeItem(at: crashURL)
        try? FileManager.default.removeItem(at: actionURL)
        try? FileManager.default.removeItem(at: cleanURL)
    }
}

/// 必须是全局函数，才能作为 C 函数指针传给 NSSetUncaughtExceptionHandler
private func handleUncaughtException(_ exception: NSException) {
    let text = """
    \(Date())
    \(exception.name.rawValue)
    \(exception.reason ?? "")
    \(exception.callStackSymbols.joined(separator: "\n"))
    """
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let url = directory.appendingPathComponent("fb_last_crash.txt")
    try? text.write(to: url, atomically: true, encoding: .utf8)
}
