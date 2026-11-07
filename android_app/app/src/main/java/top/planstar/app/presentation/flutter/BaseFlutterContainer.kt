package top.planstar.app.presentation.flutter

import android.app.Activity
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import top.planstar.app.PlanstarApp
import top.planstar.app.data.local.MMKVStore
import top.planstar.app.di.ServiceLocator
import top.planstar.app.presentation.login.LoginActivity
import top.planstar.app.presentation.reader.ReaderActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 自研 Flutter 混合开发容器（对应原 APK `com.qidian.QDReader.flutter.BaseFlutterActivity`）。
 *
 * 与原项目对齐的设计：
 * - 通过 [FlutterEngineGroup] 共享同一份 VM / snapshot，每个 routePath 一个引擎并放入
 *   [FlutterEngineCache]，FlutterFragment.withCachedEngine(route) 复用；
 * - 通道 / 方法 / 错误码统一定义在 [BridgeProtocol]：
 *   Flutter → 原生使用 [BridgeProtocol.CHANNEL_METHOD_CALL]；
 *   原生 → Flutter 使用 [BridgeProtocol.CHANNEL_NOTIFY]，登录态方法
 *   [BridgeProtocol.METHOD_USER_LOGIN_STATUS]，载荷 "1"/"2"；
 *   同时通过 [BridgeProtocol.CHANNEL_EVENT] 事件通道广播同一份登录态（与 iOS 一致）。
 *
 * 性能与可靠性（混合开发的两类高频事故）：
 * 1. 引擎预热：宿主首帧后错峰创建，避免首次切 Tab 时在主线程现起引擎造成卡顿；
 * 2. 调用时序：Dart 侧启动完成后回调 [BridgeProtocol.METHOD_FLUTTER_READY] 握手，原生在引擎
 *    未就绪时发起的推送先入队，就绪后再 flush —— 避免 MethodChannel 消息被静默丢弃。
 */
object BaseFlutterContainer {

    const val ROUTE_BOOK_CATEGORY = "/book_category"
    const val ROUTE_MINE = "/mine"

    /** 每条路由最多缓存的待发消息，防止引擎长时间未就绪导致队列无界增长 */
    private const val MAX_PENDING_PER_ROUTE = 8

    /** 第二个引擎的错峰创建延迟，避免启动阶段出现长帧 */
    private const val SECOND_ENGINE_DELAY_MS = 600L

    private val engineGroup: FlutterEngineGroup by lazy { FlutterEngineGroup(PlanstarApp.appContext) }

    /** 以下结构仅在主线程读写（引擎创建、通道回调、Activity 调用都发生在主线程） */
    private val engines = HashMap<String, FlutterEngine>()
    private val channels = HashMap<String, MethodChannel>()
    private val eventChannels = HashMap<String, EventChannel>()
    private val readyRoutes = HashSet<String>()
    private val pendingCalls = HashMap<String, MutableList<PendingCall>>()

    /** 事件通道已订阅的 sink（Dart 侧 onListen 后写入，onCancel 后移除），与 channels 同生命周期 */
    private val eventSinks = HashMap<String, EventChannel.EventSink>()

    private data class PendingCall(
        val method: String,
        val args: Any?,
        val isEvent: Boolean,
    )

    private var warmUpStarted = false

    /**
     * 当前承载 Flutter 页面的 Activity（弱引用）。
     * 原生跳转优先使用它而不是 applicationContext：避免 NEW_TASK 建出独立任务
     * （返回栈错乱 / 重复实例），也规避部分 ROM 对“非 Activity 上下文启动界面”的拦截。
     */
    private var hostActivityRef: java.lang.ref.WeakReference<Activity>? = null

    fun attachHost(activity: Activity) {
        hostActivityRef = java.lang.ref.WeakReference(activity)
    }

    fun detachHost(activity: Activity) {
        if (hostActivityRef?.get() === activity) hostActivityRef = null
    }

    private fun startActivity(intent: Intent) {
        val host = hostActivityRef?.get()
        if (host != null && !host.isFinishing) {
            host.startActivity(intent)
        } else {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            PlanstarApp.appContext.startActivity(intent)
        }
    }

    /**
     * 预热全部 Flutter 引擎（必须在主线程调用）。
     * 两个引擎依次创建并错峰，避免在同一次 vsync 里连续创建两个引擎造成长帧。
     */
    fun warmUp() {
        if (warmUpStarted) return
        warmUpStarted = true
        engineFor(ROUTE_BOOK_CATEGORY)
        Handler(Looper.getMainLooper()).postDelayed({
            engineFor(ROUTE_MINE)
        }, SECOND_ENGINE_DELAY_MS)
    }

    /** 获取（必要时创建并注册到 FlutterEngineCache）指定路由的引擎。 */
    fun engineFor(route: String): FlutterEngine = engines.getOrPut(route) { createEngine(route) }

    private fun createEngine(route: String): FlutterEngine {
        val startedAt = SystemClock.elapsedRealtime()
        // 注意：FlutterEngineGroup 会自行创建默认 DartEntrypoint，
        // 不要手动传入 DartEntrypoint.createDefault()（会触发
        // "DartEntrypoints can only be created once a FlutterEngine is created" 断言）。
        val options = FlutterEngineGroup.Options(PlanstarApp.appContext)
            .setInitialRoute(route)
        val engine = engineGroup.createAndRunEngine(options)
        registerMethodChannel(route, engine)
        registerEventChannel(route, engine)
        FlutterEngineCache.getInstance().put(route, engine)
        logPerf("engine_create", route, SystemClock.elapsedRealtime() - startedAt)
        return engine
    }

    /** 仅调试包输出性能埋点，release 不做任何日志与额外字符串拼接 */
    private val isDebuggable: Boolean
        get() = (PlanstarApp.appContext.applicationInfo.flags and
            ApplicationInfo.FLAG_DEBUGGABLE) != 0

    private fun logPerf(event: String, route: String, cost: Long) {
        if (!isDebuggable) return
        Log.d(BridgeProtocol.TAG, "[${BridgeProtocol.TAG}] $event route=$route cost=${cost}ms")
    }

    private fun registerMethodChannel(route: String, engine: FlutterEngine) {
        val channel = MethodChannel(
            engine.dartExecutor.binaryMessenger,
            BridgeProtocol.CHANNEL_METHOD_CALL,
        )
        channel.setMethodCallHandler { call, result ->
            handleMethodCall(route, call, result)
        }
        channels[route] = channel
    }

    private fun registerEventChannel(route: String, engine: FlutterEngine) {
        val channel = EventChannel(
            engine.dartExecutor.binaryMessenger,
            BridgeProtocol.CHANNEL_EVENT,
        )
        channel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                if (events == null) return
                eventSinks[route] = events
                // 已就绪的引擎在订阅瞬间补发当前登录态，避免「握手完成后才开始监听」漏掉事件
                if (route in readyRoutes) {
                    events.success(currentLoginStatus())
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSinks.remove(route)
            }
        })
        eventChannels[route] = channel
    }

    private fun handleMethodCall(route: String, call: MethodCall, result: MethodChannel.Result) {
        val startedAt = SystemClock.elapsedRealtime()
        var errorCode: String? = null

        if (call.method == BridgeProtocol.METHOD_FLUTTER_READY) {
            // Dart 侧启动完成：此刻起该引擎的 MethodChannel 才可以可靠收消息
            readyRoutes.add(route)
            result.success(true)
            flushPending(route)
        } else if (isReadyOnlyMethod(call.method)) {
            if (route in readyRoutes) {
                dispatchReadyMethod(call, result)
            } else {
                // 未握手时不得静默成功，否则 Dart 侧会把空数据当成真实结果
                errorCode = BridgeProtocol.CODE_NOT_READY
                result.error(errorCode, "Flutter engine is not ready: $route", null)
            }
        } else {
            errorCode = BridgeProtocol.CODE_UNSUPPORTED
            result.error(errorCode, "Unsupported method: ${call.method}", null)
        }

        logCall(call.method, startedAt, errorCode)
    }

    /** 仅允许在 flutterReady 握手完成后调用的方法 */
    private fun isReadyOnlyMethod(method: String): Boolean = when (method) {
        BridgeProtocol.METHOD_GET_USER_INFO,
        BridgeProtocol.METHOD_GET_BASE_URL,
        BridgeProtocol.METHOD_LOGOUT,
        BridgeProtocol.METHOD_OPEN_LOGIN,
        BridgeProtocol.METHOD_OPEN_READER -> true

        else -> false
    }

    private fun dispatchReadyMethod(call: MethodCall, result: MethodChannel.Result) {
        val context = PlanstarApp.appContext
        when (call.method) {
            BridgeProtocol.METHOD_GET_USER_INFO -> result.success(loginStatePayload())
            BridgeProtocol.METHOD_GET_BASE_URL -> result.success(MMKVStore.baseUrl)
            BridgeProtocol.METHOD_LOGOUT -> {
                ServiceLocator.logoutUseCase()
                result.success(true)
                notifyLoginStateChanged()
            }
            BridgeProtocol.METHOD_OPEN_LOGIN -> {
                startActivity(Intent(context, LoginActivity::class.java))
                result.success(true)
            }
            BridgeProtocol.METHOD_OPEN_READER -> {
                val title = call.argument<String>("title") ?: "示例书籍"
                val author = call.argument<String>("author") ?: ""
                val bookId = call.argument<Number>("bookId")?.toLong() ?: 0L
                startActivity(
                    Intent(context, ReaderActivity::class.java)
                        .putExtra(ReaderActivity.EXTRA_BOOK_ID, bookId)
                        .putExtra(ReaderActivity.EXTRA_TITLE, title)
                        .putExtra(ReaderActivity.EXTRA_AUTHOR, author)
                        .putExtra(ReaderActivity.EXTRA_CHAPTERS, 30)
                )
                result.success(true)
            }
            else -> Unit
        }
    }

    private fun logCall(method: String, startedAt: Long, errorCode: String?) {
        val cost = SystemClock.elapsedRealtime() - startedAt
        if (errorCode == null) {
            Log.d(BridgeProtocol.TAG, "method=$method cost=${cost}ms")
        } else {
            Log.d(BridgeProtocol.TAG, "method=$method cost=${cost}ms code=$errorCode")
        }
    }

    /**
     * 登录态变更后由原生主动推给 Flutter（登录页登录成功、退出登录）。
     * 已就绪的引擎立即收到；未就绪的先入队，握手完成后补发，不会丢消息。
     */
    fun notifyLoginStateChanged() {
        val payload = currentLoginStatus()
        pushToFlutter(BridgeProtocol.METHOD_USER_LOGIN_STATUS, payload)
        pushEvent(payload)
    }

    private fun currentLoginStatus(): String =
        if (MMKVStore.token.isNotEmpty()) {
            BridgeProtocol.LOGIN_STATUS_YES
        } else {
            BridgeProtocol.LOGIN_STATUS_NO
        }

    private fun pushToFlutter(method: String, args: Any?) {
        // 只推给已握手完成的引擎，避免消息落到还没跑起来的 Dart 隔离区
        readyRoutes.mapNotNull { channels[it] }.forEach { it.invokeMethod(method, args) }

        engines.keys.filterNot { it in readyRoutes }.forEach { route ->
            enqueue(route, method, args, isEvent = false)
        }
    }

    /** 事件通道推送：已就绪的直接下发，未就绪的入队，握手后补发 */
    private fun pushEvent(payload: Any?) {
        readyRoutes.forEach { route -> eventSinks[route]?.success(payload) }

        engines.keys.filterNot { it in readyRoutes }.forEach { route ->
            enqueue(
                route,
                BridgeProtocol.METHOD_USER_LOGIN_STATUS,
                payload,
                isEvent = true,
            )
        }
    }

    private fun enqueue(route: String, method: String, args: Any?, isEvent: Boolean) {
        val queue = pendingCalls.getOrPut(route) { mutableListOf() }
        if (queue.size >= MAX_PENDING_PER_ROUTE) queue.removeAt(0)
        queue.add(PendingCall(method, args, isEvent))
    }

    private fun flushPending(route: String) {
        val queue = pendingCalls.remove(route) ?: return
        queue.forEach { pending ->
            if (pending.isEvent) {
                eventSinks[route]?.success(pending.args)
            } else {
                channels[route]?.invokeMethod(pending.method, pending.args)
            }
        }
    }

    private fun loginStatePayload(): Map<String, Any?> = mapOf(
        "loggedIn" to MMKVStore.token.isNotEmpty(),
        "nickname" to MMKVStore.nickname,
        "token" to MMKVStore.token,
        "userId" to MMKVStore.userId,
    )
}
