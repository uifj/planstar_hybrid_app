import UIKit

/// 场景入口：根据登录态决定首屏（登录页 / 主界面）。
/// 对应 Android 通过 `LoginActivity` 判断登录态后跳转 `MainActivity` 的启动链路。
@MainActor
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .light
        let root: UIViewController = DemoStore.shared.isLoggedIn
            ? MainTabBarController()
            : LoginViewController()
        window.rootViewController = root
        AppRouter.shared.window = window
        self.window = window
        window.makeKeyAndVisible()
    }
}
