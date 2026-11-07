import Flutter
import UIKit

/// 自研 Flutter 混合开发容器（对应 Android `BaseFlutterContainer`）。
///
/// 与原项目对齐的设计：
/// - 通过 `FlutterEngineGroup` 共享同一份 VM / snapshot，每个 route 一个引擎并缓存复用；
/// - 通道命名沿用原项目：
///   Flutter → 原生 `com.yw.flutter.method_call`
///   原生 → Flutter `com.yw.flutter.notify`，登录态方法 `userLoginStatus`，载荷 "1"/"2"。
///
/// 性能与可靠性：
/// 1. 引擎预热：宿主首帧后错峰创建，避免首次切 Tab 时在主线程现起引擎造成卡顿；
/// 2. 调用时序：Dart 侧启动完成后回调 `flutterReady` 握手，原生在引擎未就绪时
///    发起的推送先入队，就绪后再 flush —— 避免 MethodChannel 消息被静默丢弃。
final class BaseFlutterContainer {

    static let shared = BaseFlutterContainer()

    /// Flutter → 原生 方法通道（与原项目同名）
    static let channelMethodCall = "com.yw.flutter.method_call"

    /// 原生 → Flutter 通知通道（与原项目同名）
    static let channelNotify = "com.yw.flutter.notify"

    static let routeBookCategory = "/book_category"
    static let routeMine = "/mine"

    private static let methodFlutterReady = "flutterReady"

    /// 原项目登录态通知方法名：payload "1" 已登录 / "2" 未登录
    private static let methodUserLoginStatus = "userLoginStatus"
    private static let loginStatusYes = "1"
    private static let loginStatusNo = "2"

    /// 每条路由最多缓存的待发消息，防止引擎长时间未就绪导致队列无界增长
    private static let maxPendingPerRoute = 8

    /// 第二个引擎的错峰创建延迟，避免启动阶段出现长帧
    private static let secondEngineDelay: TimeInterval = 0.6

    private lazy var engineGroup = FlutterEngineGroup(name: "planstar.engine.group", project: nil)

    /// 以下结构仅在主线程读写（引擎创建、通道回调、UI 调用都发生在主线程）
    private var engines: [String: FlutterEngine] = [:]
    private var channels: [String: FlutterMethodChannel] = [:]
    private var readyRoutes: Set<String> = []
    private var pendingCalls: [String: [(method: String, args: Any?)]] = [:]

    private var warmUpStarted = false

    private init() {}

    // MARK: - 引擎

    /// 预热全部 Flutter 引擎（必须在主线程调用）。
    /// 两个引擎依次创建并错峰，避免在同一次 vsync 里连续创建两个引擎造成长帧。
    func warmUp() {
        guard !warmUpStarted else { return }
        warmUpStarted = true
        _ = engine(for: BaseFlutterContainer.routeBookCategory)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(BaseFlutterContainer.secondEngineDelay * 1_000_000_000))
            _ = self.engine(for: BaseFlutterContainer.routeMine)
        }
    }

    /// 获取（必要时创建并缓存）指定路由的引擎。
    func engine(for route: String) -> FlutterEngine {
        if let engine = engines[route] {
            return engine
        }
        let engine = engineGroup.makeEngine(
            withEntrypoint: nil,
            libraryURI: nil,
            initialRoute: route
        )
        registerMethodChannel(route: route, engine: engine)
        engines[route] = engine
        return engine
    }

    private func registerMethodChannel(route: String, engine: FlutterEngine) {
        let channel = FlutterMethodChannel(
            name: BaseFlutterContainer.channelMethodCall,
            binaryMessenger: engine.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call: call, result: result, route: route)
        }
        channels[route] = channel
    }

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult, route: String) {
        switch call.method {
        // Dart 侧启动完成：此刻起该引擎的 MethodChannel 才可以可靠收消息
        case BaseFlutterContainer.methodFlutterReady:
            readyRoutes.insert(route)
            result(true)
            flushPending(route: route)

        case "getUserInfo":
            result(loginStatePayload())

        case "getBaseUrl":
            result(DemoStore.shared.baseUrl)

        case "logout":
            ServiceLocator.shared.logoutUseCase()
            result(true)
            notifyLoginStateChanged()

        case "openLogin":
            result(true)
            Task { @MainActor in
                AppRouter.shared.presentLogin()
            }

        case "openReader":
            let arguments = call.arguments as? [String: Any]
            let title = arguments?["title"] as? String ?? "示例书籍"
            let author = arguments?["author"] as? String ?? ""
            let bookId = (arguments?["bookId"] as? NSNumber)?.int64Value ?? 0
            result(true)
            Task { @MainActor in
                AppRouter.shared.presentReader(
                    bookId: bookId,
                    title: title,
                    author: author,
                    chapterCount: 30
                )
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - 登录态推送

    /// 登录态变更后由原生主动推给 Flutter（登录成功、退出登录）。
    /// 已就绪的引擎立即收到；未就绪的先入队，握手完成后补发，不会丢消息。
    func notifyLoginStateChanged() {
        pushToFlutter(
            method: BaseFlutterContainer.methodUserLoginStatus,
            args: DemoStore.shared.isLoggedIn
                ? BaseFlutterContainer.loginStatusYes
                : BaseFlutterContainer.loginStatusNo
        )
    }

    private func pushToFlutter(method: String, args: Any?) {
        // 只推给已握手完成的引擎，避免消息落到还没跑起来的 Dart 隔离区
        for route in readyRoutes {
            channels[route]?.invokeMethod(method, arguments: args)
        }

        for route in engines.keys where !readyRoutes.contains(route) {
            var queue = pendingCalls[route] ?? []
            if queue.count >= BaseFlutterContainer.maxPendingPerRoute {
                queue.removeFirst()
            }
            queue.append((method: method, args: args))
            pendingCalls[route] = queue
        }
    }

    private func flushPending(route: String) {
        guard let queue = pendingCalls.removeValue(forKey: route),
              let channel = channels[route] else {
            return
        }
        for call in queue {
            channel.invokeMethod(call.method, arguments: call.args)
        }
    }

    private func loginStatePayload() -> [String: Any] {
        [
            "loggedIn": DemoStore.shared.isLoggedIn,
            "nickname": DemoStore.shared.nickname,
            "token": DemoStore.shared.token,
            "userId": DemoStore.shared.userId,
        ]
    }
}
