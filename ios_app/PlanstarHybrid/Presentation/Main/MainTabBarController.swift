import UIKit

/// 主页面：底部 4 Tab（书架 / 书城 / 听书 / 我的）。
///
/// 其中「书城」「我的」为 Flutter 页面（`FlutterViewController` + 预热引擎混合渲染），
/// 「书架」「听书」为原生页面 —— 与 Android `MainActivity` 的混合结构保持一致。
@MainActor
final class MainTabBarController: UITabBarController {

    private var warmUpStarted = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 首帧之后再预热 Flutter 引擎（对应 Android MainActivity postDelayed 400ms）：
        // 既不影响启动首屏，又让首次切到 Flutter Tab 时引擎已 ready。
        guard !warmUpStarted else { return }
        warmUpStarted = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            BaseFlutterContainer.shared.warmUp()
        }
    }

    /// 状态栏样式跟随当前 Tab：原生页深色图标，Flutter 页（红色 AppBar）白色图标。
    override var childForStatusBarStyle: UIViewController? {
        selectedViewController
    }

    private func setupTabs() {
        let bookshelf = UINavigationController(rootViewController: BookshelfViewController())
        bookshelf.setNavigationBarHidden(true, animated: false)
        bookshelf.tabBarItem = UITabBarItem(
            title: "书架",
            image: UIImage(systemName: "books.vertical.fill"),
            tag: 0
        )

        let bookCity = FlutterContainerViewController(route: BaseFlutterContainer.routeBookCategory)
        bookCity.tabBarItem = UITabBarItem(
            title: "书城",
            image: UIImage(systemName: "bag.fill"),
            tag: 1
        )

        let listening = UINavigationController(rootViewController: ListeningViewController())
        listening.setNavigationBarHidden(true, animated: false)
        listening.tabBarItem = UITabBarItem(
            title: "听书",
            image: UIImage(systemName: "headphones"),
            tag: 2
        )

        let mine = FlutterContainerViewController(route: BaseFlutterContainer.routeMine)
        mine.tabBarItem = UITabBarItem(
            title: "我的",
            image: UIImage(systemName: "person.fill"),
            tag: 3
        )

        viewControllers = [bookshelf, bookCity, listening, mine]
        selectedIndex = 0
    }
}
