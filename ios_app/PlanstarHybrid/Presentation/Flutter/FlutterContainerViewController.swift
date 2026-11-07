import Flutter
import UIKit

/// Flutter 页面容器：把 `FlutterViewController` 作为子控制器嵌入原生 Tab。
///
/// 与 Android `FlutterFragment.withCachedEngine(route)` 等价：
/// 引擎由 `BaseFlutterContainer` 按 route 缓存并预热，这里只负责视图挂载。
@MainActor
final class FlutterContainerViewController: UIViewController {

    private let route: String

    /// 首次完成 Flutter 子控制器挂载后的回调：宿主用它统计 Tab 切换耗时。
    var onDidMount: (() -> Void)?

    private lazy var flutterViewController = FlutterViewController(
        engine: BaseFlutterContainer.shared.engine(for: route),
        nibName: nil,
        bundle: nil
    )

    init(route: String) {
        self.route = route
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        addChild(flutterViewController)
        flutterViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(flutterViewController.view)

        NSLayoutConstraint.activate([
            flutterViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            flutterViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            flutterViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            flutterViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        flutterViewController.didMove(toParent: self)
        onDidMount?()
        onDidMount = nil
    }

    /// Flutter 页面顶部为红色 AppBar → 白色状态栏图标
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}
