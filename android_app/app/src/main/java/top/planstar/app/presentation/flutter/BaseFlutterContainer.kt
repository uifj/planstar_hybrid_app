package top.planstar.app.presentation.flutter

import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import top.planstar.app.PlanstarApp
import top.planstar.app.data.local.MMKVStore
import top.planstar.app.di.ServiceLocator
import top.planstar.app.presentation.login.LoginActivity
import top.planstar.app.presentation.reader.ReaderActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.plugin.common.MethodChannel

/**
 * 自研 Flutter 混合开发容器（对应原 APK `com.qidian.QDReader.flutter.BaseFlutterActivity`）。
 *
 * 与原项目对齐的设计：
 * - 通过 [FlutterEngineGroup] 共享同一份 VM / snapshot，每个 routePath 一个引擎并放入
 *   [FlutterEngineCache]，FlutterFragment.withCachedEngine(route) 复用；
 * - 通道命名沿用原项目：
 *   Flutter → 原生：`com.yw.flutter.method_call`
 *   原生 → Flutter：`com.yw.flutter.notify`，登录态方法 `userLoginStatus`，载荷 "1"/"2"。
 *
 * 性能与可靠性（混合开发的两类高频事故）：
 * 1. 引擎预热：宿主首帧后错峰创建，避免首次切 Tab 时在主线程现起引擎造成卡顿；
 * 2. 调用时序：Dart 侧启动完成后回调 [METHOD_FLUTTER_READY] 握手，原生在引擎未就绪
 *    时发起的推送先入队，就绪后再 flush —— 避免 MethodChannel 消息被静默丢弃。
 */
object BaseFlutterContainer {

    /** Flutter → 原生 方法通道（与原项目同名） */
    const val CHANNEL_METHOD_CALL = "com.yw.flutter.method_call"

    /** 原生 → Flutter 通知通道（与原项目同名） */
    const val CHANNEL_NOTIFY = "com.yw.flutter.notify"

    const val ROUTE_BOOK_CATEGORY = "/book_category"
    const val ROUTE_MINE = "/mine"

    private const val METHOD_FLUTTER_READY = "flutterReady"

    /** 原项目登录态通知方法名：payload "1" 已登录 / "2" 未登录 */
    private const val METHOD_USER_LOGIN_STATUS = "userLoginStatus"
    private const val LOGIN_STATUS_YES = "1"
    private const val LOGIN_STATUS_NO = "2"

    /** 每条路由最多缓存的待发消息，防止引擎长时间未就绪导致队列无界增长 */
    private const val MAX_PENDING_PER_ROUTE = 8

    /** 第二个引擎的错峰创建延迟，避免启动阶段出现长帧 */
    private const val SECOND_ENGINE_DELAY_MS = 600L

    private val engineGroup: FlutterEngineGroup by lazy { FlutterEngineGroup(PlanstarApp.appContext) }

    /** 以下结构仅在主线程读写（引擎创建、通道回调、Activity 调用都发生在主线程） */
    private val engines = HashMap<String, FlutterEngine>()
    private val channels = HashMap<String, MethodChannel>()
    private val readyRoutes = HashSet<String>()
    private val pendingCalls = HashMap<String, MutableList<Pair<String, Any?>>>()

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
        // 注意：FlutterEngineGroup 会自行创建默认 DartEntrypoint，
        // 不要手动传入 DartEntrypoint.createDefault()（会触发
        // "DartEntrypoints can only be created once a FlutterEngine is created" 断言）。
        val options = FlutterEngineGroup.Options(PlanstarApp.appContext)
            .setInitialRoute(route)
        val engine = engineGroup.createAndRunEngine(options)
        registerMethodChannel(route, engine)
        FlutterEngineCache.getInstance().put(route, engine)
        return engine
    }

    private fun registerMethodChannel(route: String, engine: FlutterEngine) {
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_METHOD_CALL)
        channel.setMethodCallHandler { call, result ->
            val context = PlanstarApp.appContext
            when (call.method) {
                // Dart 侧启动完成：此刻起该引擎的 MethodChannel 才可以可靠收消息
                METHOD_FLUTTER_READY -> {
                    readyRoutes.add(route)
                    result.success(true)
                    flushPending(route)
                }
                "getUserInfo" -> result.success(loginStatePayload())
                "getBaseUrl" -> result.success(MMKVStore.baseUrl)
                "logout" -> {
                    ServiceLocator.logoutUseCase()
                    result.success(true)
                    notifyLoginStateChanged()
                }
                "openLogin" -> {
                    startActivity(Intent(context, LoginActivity::class.java))
                    result.success(true)
                }
                "openReader" -> {
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
                else -> result.notImplemented()
            }
        }
        channels[route] = channel
    }

    /**
     * 登录态变更后由原生主动推给 Flutter（登录页登录成功、退出登录）。
     * 已就绪的引擎立即收到；未就绪的先入队，握手完成后补发，不会丢消息。
     */
    fun notifyLoginStateChanged() {
        pushToFlutter(
            METHOD_USER_LOGIN_STATUS,
            if (MMKVStore.token.isNotEmpty()) LOGIN_STATUS_YES else LOGIN_STATUS_NO,
        )
    }

    private fun pushToFlutter(method: String, args: Any?) {
        // 只推给已握手完成的引擎，避免消息落到还没跑起来的 Dart 隔离区
        readyRoutes.mapNotNull { channels[it] }.forEach { it.invokeMethod(method, args) }

        engines.keys.filterNot { it in readyRoutes }.forEach { route ->
            val queue = pendingCalls.getOrPut(route) { mutableListOf() }
            if (queue.size >= MAX_PENDING_PER_ROUTE) queue.removeAt(0)
            queue.add(method to args)
        }
    }

    private fun flushPending(route: String) {
        val queue = pendingCalls.remove(route) ?: return
        val channel = channels[route] ?: return
        queue.forEach { (method, args) -> channel.invokeMethod(method, args) }
    }

    private fun loginStatePayload(): Map<String, Any?> = mapOf(
        "loggedIn" to MMKVStore.token.isNotEmpty(),
        "nickname" to MMKVStore.nickname,
        "token" to MMKVStore.token,
        "userId" to MMKVStore.userId,
    )
}
