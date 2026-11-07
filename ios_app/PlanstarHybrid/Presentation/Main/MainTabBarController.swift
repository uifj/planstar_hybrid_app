import UIKit

/// 主页面：底部 4 Tab（书架 / 书城 / 听书 / 我的）。
///
/// 其中「书城」「我的」为 Flutter 页面（`FlutterViewController` + 预热引擎混合渲染），
/// 「书架」「听书」为原生页面 —— 与 Android `MainActivity` 的混合结构保持一致。
@MainActor
final class MainTabBarController: UITabBarController {

    private var warmUpStarted = false

    /// Flutter Tab 切换计时起点（shouldSelect 回调开始）
    private var tabSwitchStartedAt: CFAbsoluteTime?

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
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

        let bookCity = makeFlutterTab(
            route: BaseFlutterContainer.routeBookCategory,
            title: "书城",
            imageName: "bag.fill",
            tag: 1
        )

        let listening = UINavigationController(rootViewController: ListeningViewController())
        listening.setNavigationBarHidden(true, animated: false)
        listening.tabBarItem = UITabBarItem(
            title: "听书",
            image: UIImage(systemName: "headphones"),
            tag: 2
        )

        let mine = makeFlutterTab(
            route: BaseFlutterContainer.routeMine,
            title: "我的",
            imageName: "person.fill",
            tag: 3
        )

        viewControllers = [bookshelf, bookCity, listening, mine]
        selectedIndex = 0
    }

    /// 创建 Flutter Tab 容器，并在首次挂载完成时结算 tab_switch 埋点。
    private func makeFlutterTab(
        route: String,
        title: String,
        imageName: String,
        tag: Int
    ) -> FlutterContainerViewController {
        let controller = FlutterContainerViewController(route: route)
        controller.onDidMount = { [weak self] in
            self?.finishTabSwitch(route: route)
        }
        controller.tabBarItem = UITabBarItem(
            title: title,
            image: UIImage(systemName: imageName),
            tag: tag
        )
        return controller
    }
}

extension MainTabBarController: UITabBarControllerDelegate {

    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        // 计时起点：Tab 选中回调开始；仅 Flutter Tab 消费该打点
        tabSwitchStartedAt = flutterRoute(of: viewController) != nil
            ? CFAbsoluteTimeGetCurrent()
            : nil
        return true
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        guard let route = flutterRoute(of: viewController) else { return }
        // 首次选中时视图可能尚未加载，交给 onDidMount 结算；再次切回则直接结算
        guard viewController.isViewLoaded else { return }
        finishTabSwitch(route: route)
    }

    /// Flutter Tab 与路由的映射（tag 与 setupTabs 保持一致）
    private func flutterRoute(of viewController: UIViewController) -> String? {
        switch viewController.tabBarItem.tag {
        case 1: return BaseFlutterContainer.routeBookCategory
        case 3: return BaseFlutterContainer.routeMine
        default: return nil
        }
    }

    private func finishTabSwitch(route: String) {
        guard let startedAt = tabSwitchStartedAt else { return }
        tabSwitchStartedAt = nil
        // 仅 Debug 输出性能埋点，Release 不做日志字符串拼接
        #if DEBUG
        let cost = String(format: "%.1f", (CFAbsoluteTimeGetCurrent() - startedAt) * 1000)
        print("[\(BridgeProtocol.tag)] tab_switch route=\(route) cost=\(cost)ms")
        #endif
    }
}
