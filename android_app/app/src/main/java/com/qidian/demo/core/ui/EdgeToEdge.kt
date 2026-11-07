package com.qidian.demo.core.ui

import android.view.View
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.core.view.updatePadding

/**
 * 系统栏 / 安全区统一工具（core 层，所有 presentation 页面共用）。
 *
 * - targetSdk 36 在 Android 15+ 会被强制 edge-to-edge，内容绘制到状态栏、导航栏后面；
 * - 这里主动对全版本开启 edge-to-edge，并统一通过 insets 为内容追加安全区 padding，
 *   保证刘海屏、挖孔屏、异形屏以及手势导航/三键导航下都不遮挡、不偏移。
 */

/** 切换状态栏 / 导航栏图标明暗（true = 深色图标，适合浅色背景）。 */
fun AppCompatActivity.setSystemBarStyle(lightStatusBar: Boolean, lightNavBar: Boolean = true) {
    WindowInsetsControllerCompat(window, window.decorView).apply {
        isAppearanceLightStatusBars = lightStatusBar
        isAppearanceLightNavigationBars = lightNavBar
    }
}

/** 开启内容铺满系统栏，并同步状态栏/导航栏图标明暗。 */
fun AppCompatActivity.enableEdgeToEdge(lightStatusBar: Boolean, lightNavBar: Boolean = true) {
    WindowCompat.setDecorFitsSystemWindows(window, false)
    setSystemBarStyle(lightStatusBar, lightNavBar)
}

/**
 * 给 View 追加系统栏安全区 padding（保留原有 padding 作为基准）。
 * 不消费 insets，保证 Fragment 内的子 View 仍能收到同一份 insets。
 *
 * @param top 追加状态栏 + 刘海/挖孔的安全区
 * @param bottom 追加导航栏安全区（ime = true 时同时避让软键盘）
 * @param horizontal 追加左右安全区（横屏刘海/挖孔）
 * @param ime 软键盘弹出时追加底部 inset
 */
fun View.applyInsetsPadding(
    top: Boolean = false,
    bottom: Boolean = false,
    horizontal: Boolean = false,
    ime: Boolean = false,
) {
    val baseLeft = paddingLeft
    val baseTop = paddingTop
    val baseRight = paddingRight
    val baseBottom = paddingBottom

    ViewCompat.setOnApplyWindowInsetsListener(this) { view, insets ->
        val bars = insets.getInsets(
            WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
        )
        val imeBottom = if (ime) {
            insets.getInsets(WindowInsetsCompat.Type.ime()).bottom
        } else {
            0
        }
        view.updatePadding(
            left = baseLeft + if (horizontal) bars.left else 0,
            top = baseTop + if (top) bars.top else 0,
            right = baseRight + if (horizontal) bars.right else 0,
            bottom = baseBottom + if (bottom) maxOf(bars.bottom, imeBottom) else 0,
        )
        insets
    }
    ViewCompat.requestApplyInsets(this)
}

/** 让一个 0dp 高度的 View 自动等于状态栏（含刘海）高度，用作状态栏底色遮罩。 */
fun View.applyStatusBarScrim() {
    ViewCompat.setOnApplyWindowInsetsListener(this) { view, insets ->
        val top = insets.getInsets(
            WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
        ).top
        if (view.layoutParams.height != top) {
            view.layoutParams = view.layoutParams.apply { height = top }
        }
        insets
    }
    ViewCompat.requestApplyInsets(this)
}
