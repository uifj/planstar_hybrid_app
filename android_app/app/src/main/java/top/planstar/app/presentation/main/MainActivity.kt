package top.planstar.app.presentation.main

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.os.SystemClock
import android.util.Log
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import top.planstar.app.R
import top.planstar.app.PlanstarApp
import top.planstar.app.core.ui.applyInsetsPadding
import top.planstar.app.core.ui.enableEdgeToEdge
import top.planstar.app.core.ui.setSystemBarStyle
import top.planstar.app.databinding.ActivityMainBinding
import top.planstar.app.presentation.flutter.BaseFlutterContainer
import top.planstar.app.presentation.flutter.BridgeProtocol
import io.flutter.embedding.android.FlutterFragment

/**
 * 主页面：底部 4 Tab（书架 / 书城 / 听书 / 我的）。
 * 其中“书城”、“我的”为 Flutter 页面（FlutterFragment + cachedEngine 混合渲染），
 * “书架”、“听书”为原生页面。
 *
 * 安全区：底部导航栏追加导航栏 inset；顶部状态栏区域由各 Tab 的标题栏/Flutter AppBar
 * 自身上色并由 insets 避让，保证刘海屏、挖孔屏下标题不被遮挡。
 */
class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private var currentFragment: Fragment? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(lightStatusBar = true, lightNavBar = true)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // 底部导航：追加导航栏安全区 + 横屏左右安全区
        binding.bottomNav.applyInsetsPadding(bottom = true, horizontal = true)

        // 首帧之后再预热 Flutter 引擎：既不影响启动首屏，又让首次切到 Flutter Tab 时
        // 引擎已经 ready（两个引擎共享同一 Isolate Group，内存与启动成本更低）。
        // 延迟 400ms 错开启动动画，避免预热占用首屏的绘制时间。
        binding.root.postDelayed({ BaseFlutterContainer.warmUp() }, 400L)

        if (savedInstanceState == null) {
            switchTo(
                TAG_BOOKSHELF,
                lightStatusBar = true,
                immediate = true,
            ) { BookshelfFragment() }
        } else {
            currentFragment = supportFragmentManager.primaryNavigationFragment
                ?: supportFragmentManager.findFragmentById(R.id.fragmentContainer)
        }

        binding.bottomNav.setOnItemSelectedListener { item ->
            // 计时起点：Tab 选中回调开始；仅 Flutter Tab 会消费该打点
            val startedAt = SystemClock.elapsedRealtime()
            when (item.itemId) {
                R.id.nav_bookshelf -> switchTo(TAG_BOOKSHELF, lightStatusBar = true) {
                    BookshelfFragment()
                }
                R.id.nav_bookcity -> switchTo(
                    TAG_BOOKCITY,
                    lightStatusBar = false,
                    perfRoute = BaseFlutterContainer.ROUTE_BOOK_CATEGORY,
                    startedAt = startedAt,
                ) {
                    flutterTab(BaseFlutterContainer.ROUTE_BOOK_CATEGORY)
                }
                R.id.nav_listening -> switchTo(TAG_LISTENING, lightStatusBar = true) {
                    ListeningFragment()
                }
                R.id.nav_mine -> switchTo(
                    TAG_MINE,
                    lightStatusBar = false,
                    perfRoute = BaseFlutterContainer.ROUTE_MINE,
                    startedAt = startedAt,
                ) {
                    flutterTab(BaseFlutterContainer.ROUTE_MINE)
                }
                else -> return@setOnItemSelectedListener false
            }
            true
        }
    }

    override fun onResume() {
        super.onResume()
        // 供 Flutter 侧发起的原生跳转（登录/阅读）使用当前 Activity 上下文
        BaseFlutterContainer.attachHost(this)
    }

    override fun onDestroy() {
        BaseFlutterContainer.detachHost(this)
        super.onDestroy()
    }

    /**
     * Tab 切换使用 add/show/hide（而不是 replace），避免每次切换都重建视图、
     * 也避免书架在网络请求完成后再次刷新；四个 Tab 的页面状态得以保留。
     */
    private fun switchTo(
        tag: String,
        lightStatusBar: Boolean,
        immediate: Boolean = false,
        perfRoute: String? = null,
        startedAt: Long = 0L,
        create: () -> Fragment,
    ): Fragment {
        // 原生 Tab 标题栏为白色 → 深色状态栏图标；Flutter Tab 为红色 AppBar → 白色图标
        setSystemBarStyle(lightStatusBar = lightStatusBar, lightNavBar = true)

        val manager = supportFragmentManager
        val target = manager.findFragmentByTag(tag) ?: create()
        if (target === currentFragment) return target

        val transaction = manager.beginTransaction().apply {
            currentFragment?.let { hide(it) }
            if (target.isAdded) show(target) else add(R.id.fragmentContainer, target, tag)
            setPrimaryNavigationFragment(target)
        }
        // 首次进入必须同步建好，后续切换改为异步提交：
        // FlutterFragment 首次挂载到已缓存引擎时要在主线程上跑完 Dart 首帧（debug 下上百毫秒），
        // commitNow 会把这段耗时压进点击事件里，导致点击后立即卡住；
        // commit 让点击/水波纹先出一帧，事务在下一个 vsync 执行。
        if (immediate) transaction.commitNow() else transaction.commit()
        currentFragment = target
        // 终点：FlutterFragment 已提交挂载（commit 下事务在下一帧执行，首帧耗时不再阻塞点击响应）
        if (perfRoute != null) logTabSwitch(perfRoute, startedAt)
        return target
    }

    /** 仅调试包输出 Tab 切换埋点，release 不产生日志 */
    private fun logTabSwitch(route: String, startedAt: Long) {
        val debuggable = (PlanstarApp.appContext.applicationInfo.flags and
            ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!debuggable) return
        val cost = SystemClock.elapsedRealtime() - startedAt
        Log.d(
            BridgeProtocol.TAG,
            "[${BridgeProtocol.TAG}] tab_switch route=$route cost=${cost}ms",
        )
    }

    private fun flutterTab(route: String): Fragment =
        FlutterFragment.withCachedEngine(route)
            // Flutter 内部路由（搜索/书籍详情）由 Flutter 消费返回键；根路由时回落到 Activity 默认行为
            .shouldAutomaticallyHandleOnBackPressed(true)
            .destroyEngineWithFragment(false)
            .build()

    companion object {
        private const val TAG_BOOKSHELF = "tab_bookshelf"
        private const val TAG_BOOKCITY = "tab_bookcity"
        private const val TAG_LISTENING = "tab_listening"
        private const val TAG_MINE = "tab_mine"
    }
}
