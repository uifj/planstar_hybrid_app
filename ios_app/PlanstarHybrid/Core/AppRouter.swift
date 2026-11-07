import UIKit

/// 全局路由：负责根控制器切换、登录页与阅读页的呈现。
///
/// 与 Android 侧 Activity 栈的对应关系：
/// - Android 登录成功 `startActivity(MainActivity)` → iOS 切换 window.rootViewController
/// - Android `openLogin` / `openReader` 启动 Activity → iOS 模态呈现，由原生统一管理
@MainActor
final class AppRouter {

    static let shared = AppRouter()

    /// 由 SceneDelegate 注入；未注入时回退到当前 keyWindow。
    weak var window: UIWindow?

    private init() {}

    // MARK: - 根控制器

    /// 登录成功后进入主界面（对应 Android `MainActivity`）
    func showMain() {
        setRoot(MainTabBarController(), animated: true)
    }

    /// 展示登录页（对应 Android `LoginActivity`）
    func showLogin() {
        setRoot(LoginViewController(), animated: true)
    }

    /// 从原生或 Flutter 侧调起登录页；登录成功后仅关闭登录页，回到调用方。
    func presentLogin() {
        guard let top = topViewController else { return }
        guard !(top is LoginViewController) else { return }
        let login = LoginViewController()
        login.modalPresentationStyle = .fullScreen
        top.present(login, animated: true)
    }

    /// 打开阅读页（对应 Android `ReaderActivity`）
    func presentReader(bookId: Int64, title: String, author: String, chapterCount: Int) {
        guard let top = topViewController else { return }
        let reader = ReaderViewController(
            bookId: bookId,
            title: title,
            author: author,
            chapterCount: chapterCount
        )
        reader.modalPresentationStyle = .fullScreen
        top.present(reader, animated: true)
    }

    // MARK: - 工具

    var topViewController: UIViewController? {
        topMost(of: activeWindow?.rootViewController)
    }

    private var activeWindow: UIWindow? {
        if let window { return window }
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    private func setRoot(_ viewController: UIViewController, animated: Bool) {
        guard let window = activeWindow else { return }
        guard animated else {
            window.rootViewController = viewController
            return
        }
        UIView.transition(with: window, duration: 0.28, options: .transitionCrossDissolve) {
            window.rootViewController = viewController
        }
    }

    private func topMost(of base: UIViewController?) -> UIViewController? {
        guard let base else { return nil }
        if let presented = base.presentedViewController {
            return topMost(of: presented)
        }
        if let navigation = base as? UINavigationController {
            return topMost(of: navigation.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topMost(of: tab.selectedViewController)
        }
        return base
    }
}
