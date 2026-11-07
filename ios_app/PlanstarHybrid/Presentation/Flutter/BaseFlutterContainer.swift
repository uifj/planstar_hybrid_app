import Flutter
import UIKit

/// Flutter 桥接协议常量（与 Android `BridgeProtocol.kt` 保持一致）。
///
/// 所有通道名、方法名、登录态载荷与错误码只在此处定义，避免两端命名漂移
/// 导致消息静默丢失。
enum BridgeProtocol {

    /// 桥接日志统一 TAG
    static let tag = "PlanstarBridge"

    /// Flutter → 原生 方法通道（与原项目同名，不可修改）
    static let channelMethodCall = "com.yw.flutter.method_call"

    /// 原生 → Flutter 通知通道（与原项目同名，不可修改）
    static let channelNotify = "com.yw.flutter.notify"

    /// 原生 → Flutter 事件通道（登录态变更事件）
    static let channelEvent = "com.yw.flutter.event"

    /// Dart 侧启动完成握手
    static let methodFlutterReady = "flutterReady"
    static let methodGetUserInfo = "getUserInfo"
    static let methodGetBaseUrl = "getBaseUrl"
    static let methodLogout = "logout"
    static let methodOpenLogin = "openLogin"
    static let methodOpenReader = "openReader"

    /// 登录态通知方法名：载荷 `loginStatusYes` 已登录 / `loginStatusNo` 未登录
    static let methodUserLoginStatus = "userLoginStatus"

    static let loginStatusYes = "1"
    static let loginStatusNo = "2"

    /// Flutter 尚未握手完成（未收到 flutterReady）
    static let codeNotReady = "NOT_READY"

    /// 未知 / 未支持的方法
    static let codeUnsupported = "UNSUPPORTED"

    /// 调用超时
    static let codeTimeout = "TIMEOUT"

    /// 原生侧内部异常
    static let codeInternal = "INTERNAL"
}

/// 自研 Flutter 混合开发容器（对应 Android `BaseFlutterContainer`）。
///
/// 与原项目对齐的设计：
/// - 通过 `FlutterEngineGroup` 共享同一份 VM / snapshot，每个 route 一个引擎并缓存复用；
/// - 通道命名沿用原项目（常量见上方 `BridgeProtocol`）：
///   Flutter → 原生使用 `channelMethodCall`；
///   原生 → Flutter 使用 `channelNotify`，登录态方法 `methodUserLoginStatus`，载荷 "1"/"2"；
///   另提供事件通道 `channelEvent` 推送同一份登录态事件。
///
/// 性能与可靠性：
/// 1. 引擎预热：宿主首帧后错峰创建，避免首次切 Tab 时在主线程现起引擎造成卡顿；
/// 2. 调用时序：Dart 侧启动完成后回调 `flutterReady` 握手，原生在引擎未就绪时
///    发起的推送先入队，就绪后再 flush —— 避免 MethodChannel 消息被静默丢弃。
final class BaseFlutterContainer {

    static let shared = BaseFlutterContainer()

    static let routeBookCategory = "/book_category"
    static let routeMine = "/mine"

    /// 每条路由最多缓存的待发消息，防止引擎长时间未就绪导致队列无界增长
    private static let maxPendingPerRoute = 8

    /// 第二个引擎的错峰创建延迟，避免启动阶段出现长帧
    private static let secondEngineDelay: TimeInterval = 0.6

    private lazy var engineGroup = FlutterEngineGroup(name: "planstar.engine.group", project: nil)

    /// 以下结构仅在主线程读写（引擎创建、通道回调、UI 调用都发生在主线程）
    private var engines: [String: FlutterEngine] = [:]
    private var channels: [String: FlutterMethodChannel] = [:]
    private var readyRoutes: Set<String> = []
    private var pendingCalls: [String: [(method: String, args: Any?, isEvent: Bool)]] = [:]

    /// 事件通道与 StreamHandler 均由容器持有，避免引擎侧只弱引用导致被释放
    private var eventChannels: [String: FlutterEventChannel] = [:]
    private var eventHandlers: [String: BridgeEventStreamHandler] = [:]

    /// 已订阅事件通道的 sink（Dart 侧 onListen 后写入，onCancel 后移除）
    fileprivate var eventSinks: [String: FlutterEventSink] = [:]

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
        let startedAt = CFAbsoluteTimeGetCurrent()
        let engine = engineGroup.makeEngine(
            withEntrypoint: nil,
            libraryURI: nil,
            initialRoute: route
        )
        registerMethodChannel(route: route, engine: engine)
        registerEventChannel(route: route, engine: engine)
        engines[route] = engine
        // 仅 Debug 输出性能埋点，Release 不做日志字符串拼接
        #if DEBUG
        let cost = String(format: "%.1f", (CFAbsoluteTimeGetCurrent() - startedAt) * 1000)
        print("[\(BridgeProtocol.tag)] engine_create route=\(route) cost=\(cost)ms")
        #endif
        return engine
    }

    private func registerMethodChannel(route: String, engine: FlutterEngine) {
        let channel = FlutterMethodChannel(
            name: BridgeProtocol.channelMethodCall,
            binaryMessenger: engine.binaryMessenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call: call, result: result, route: route)
        }
        channels[route] = channel
    }

    private func registerEventChannel(route: String, engine: FlutterEngine) {
        let channel = FlutterEventChannel(
            name: BridgeProtocol.channelEvent,
            binaryMessenger: engine.binaryMessenger
        )
        let handler = BridgeEventStreamHandler(container: self, route: route)
        channel.setStreamHandler(handler)
        eventChannels[route] = channel
        eventHandlers[route] = handler
    }

    // MARK: - Flutter → 原生

    private func handle(call: FlutterMethodCall, result: @escaping FlutterResult, route: String) {
        let startedAt = ProcessInfo.processInfo.systemUptime
        var errorCode: String?

        if call.method == BridgeProtocol.methodFlutterReady {
            // Dart 侧启动完成：此刻起该引擎的 MethodChannel 才可以可靠收消息
            readyRoutes.insert(route)
            result(true)
            flushPending(route: route)
        } else if isReadyOnlyMethod(call.method) {
            if readyRoutes.contains(route) {
                dispatchReadyMethod(call: call, result: result)
            } else {
                // 未握手时不得静默成功，否则 Dart 侧会把空数据当成真实结果
                errorCode = BridgeProtocol.codeNotReady
                result(FlutterError(
                    code: BridgeProtocol.codeNotReady,
                    message: "Flutter engine is not ready: \(route)",
                    details: nil
                ))
            }
        } else {
            errorCode = BridgeProtocol.codeUnsupported
            result(FlutterError(
                code: BridgeProtocol.codeUnsupported,
                message: "Unsupported method: \(call.method)",
                details: nil
            ))
        }

        logCall(method: call.method, startedAt: startedAt, errorCode: errorCode)
    }

    /// 仅允许在 flutterReady 握手完成后调用的方法
    private func isReadyOnlyMethod(_ method: String) -> Bool {
        switch method {
        case BridgeProtocol.methodGetUserInfo,
             BridgeProtocol.methodGetBaseUrl,
             BridgeProtocol.methodLogout,
             BridgeProtocol.methodOpenLogin,
             BridgeProtocol.methodOpenReader:
            return true
        default:
            return false
        }
    }

    private func dispatchReadyMethod(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case BridgeProtocol.methodGetUserInfo:
            result(loginStatePayload())

        case BridgeProtocol.methodGetBaseUrl:
            result(DemoStore.shared.baseUrl)

        case BridgeProtocol.methodLogout:
            ServiceLocator.shared.logoutUseCase()
            result(true)
            notifyLoginStateChanged()

        case BridgeProtocol.methodOpenLogin:
            result(true)
            Task { @MainActor in
                AppRouter.shared.presentLogin()
            }

        case BridgeProtocol.methodOpenReader:
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
            result(FlutterError(
                code: BridgeProtocol.codeUnsupported,
                message: "Unsupported method: \(call.method)",
                details: nil
            ))
        }
    }

    private func logCall(method: String, startedAt: TimeInterval, errorCode: String?) {
        let cost = String(format: "%.1f", (ProcessInfo.processInfo.systemUptime - startedAt) * 1000)
        if let errorCode = errorCode {
            print("[\(BridgeProtocol.tag)] method=\(method) cost=\(cost)ms code=\(errorCode)")
        } else {
            print("[\(BridgeProtocol.tag)] method=\(method) cost=\(cost)ms")
        }
    }

    // MARK: - 登录态推送

    /// 登录态变更后由原生主动推给 Flutter（登录成功、退出登录）。
    /// 已就绪的引擎立即收到；未就绪的先入队，握手完成后补发，不会丢消息。
    func notifyLoginStateChanged() {
        let payload = DemoStore.shared.isLoggedIn
            ? BridgeProtocol.loginStatusYes
            : BridgeProtocol.loginStatusNo

        pushToFlutter(method: BridgeProtocol.methodUserLoginStatus, args: payload)
        pushEvent(payload)
    }

    private func pushToFlutter(method: String, args: Any?) {
        // 只推给已握手完成的引擎，避免消息落到还没跑起来的 Dart 隔离区
        for route in readyRoutes {
            channels[route]?.invokeMethod(method, arguments: args)
        }

        for route in engines.keys where !readyRoutes.contains(route) {
            enqueue(route: route, method: method, args: args, isEvent: false)
        }
    }

    private func pushEvent(_ payload: Any?) {
        for route in readyRoutes {
            eventSinks[route]?(payload)
        }

        for route in engines.keys where !readyRoutes.contains(route) {
            enqueue(
                route: route,
                method: BridgeProtocol.methodUserLoginStatus,
                args: payload,
                isEvent: true
            )
        }
    }

    private func enqueue(route: String, method: String, args: Any?, isEvent: Bool) {
        var queue = pendingCalls[route] ?? []
        if queue.count >= BaseFlutterContainer.maxPendingPerRoute {
            queue.removeFirst()
        }
        queue.append((method: method, args: args, isEvent: isEvent))
        pendingCalls[route] = queue
    }

    private func flushPending(route: String) {
        guard let queue = pendingCalls.removeValue(forKey: route) else {
            return
        }
        for item in queue {
            if item.isEvent {
                eventSinks[route]?(item.args)
            } else {
                channels[route]?.invokeMethod(item.method, arguments: item.args)
            }
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

/// 事件通道的 StreamHandler：只记录 / 清理 sink，不持有容器（避免循环引用）。
private final class BridgeEventStreamHandler: NSObject, FlutterStreamHandler {

    private weak var container: BaseFlutterContainer?
    private let route: String

    init(container: BaseFlutterContainer, route: String) {
        self.container = container
        self.route = route
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        container?.eventSinks[route] = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        container?.eventSinks.removeValue(forKey: route)
        return nil
    }
}
