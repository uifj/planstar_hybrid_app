package com.qidian.demo.presentation.reader

import android.content.res.ColorStateList
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.MotionEvent
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.isVisible
import androidx.core.view.updatePadding
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.qidian.demo.R
import com.qidian.demo.core.ui.enableEdgeToEdge
import com.qidian.demo.core.ui.setSystemBarStyle
import com.qidian.demo.data.local.MMKVStore
import com.qidian.demo.databinding.ActivityReaderBinding
import com.qidian.demo.di.ServiceLocator
import com.qidian.demo.domain.model.BookItem
import com.qidian.demo.domain.model.Chapter

/**
 * 阅读页（对应原项目 ui.activity.chapter 阅读模块）：
 * - 点击正文切换顶部/底部工具栏
 * - 底部栏：目录（章节列表弹窗）、字体 A-/A+、主题（白/黄/绿/黑四种阅读模式）
 * - 音量键翻页、章节末尾点击进入下一章、返回键先收起工具栏
 * - 阅读字号与主题通过 MMKV 记忆
 *
 * 分层：目录与正文通过 domain 用例获取，阅读设置持久化在 data 层 MMKVStore。
 *
 * 安全区：开启 edge-to-edge，正文避让状态栏/刘海，工具栏避让状态栏与导航栏，
 * 四种阅读主题下同步切换状态栏/导航栏图标明暗。
 */
class ReaderActivity : AppCompatActivity() {

    private lateinit var binding: ActivityReaderBinding

    private var currentChapter = 0
    private var totalChapters = 30
    private var fontSize = 18f
    private var themeIndex = 0

    private var book: BookItem = BookItem()
    private lateinit var chapters: List<Chapter>

    private var downX = 0f
    private var downY = 0f

    private var statusBarInset = 0
    private var navBarInset = 0
    private var horizontalInset = 0

    private val loadChapters = ServiceLocator.loadChaptersUseCase
    private val loadChapterContent = ServiceLocator.loadChapterContentUseCase

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge(lightStatusBar = true, lightNavBar = true)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }

        binding = ActivityReaderBinding.inflate(layoutInflater)
        setContentView(binding.root)

        book = BookItem(
            BookId = intent.getLongExtra(EXTRA_BOOK_ID, 0),
            BookName = intent.getStringExtra(EXTRA_TITLE) ?: "示例书籍",
            Author = intent.getStringExtra(EXTRA_AUTHOR) ?: "起点作者",
        )
        totalChapters = intent.getIntExtra(EXTRA_CHAPTERS, 30)
        chapters = loadChapters(book.BookId, totalChapters)

        fontSize = MMKVStore.readerFontSize.toFloat()
        themeIndex = MMKVStore.readerTheme.coerceIn(0, themeNames.size - 1)

        binding.tvBookTitle.text = book.BookName.orEmpty()
        binding.tvChapterAuthor.text = book.Author.orEmpty()

        binding.btnBack.setOnClickListener { finish() }
        binding.btnCatalog.setOnClickListener { showCatalog() }
        binding.btnFontMinus.setOnClickListener { changeFontSize(-1) }
        binding.btnFontPlus.setOnClickListener { changeFontSize(1) }
        binding.btnTheme.setOnClickListener { cycleTheme() }
        binding.tvChapterEnd.setOnClickListener { goNextChapter() }

        // 点击空白区域切换工具栏显隐（ScrollView 不触发 OnClick，改用轻触检测）
        binding.contentArea.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.x
                    downY = event.y
                }
                MotionEvent.ACTION_UP -> {
                    if (kotlin.math.abs(event.x - downX) < 30 && kotlin.math.abs(event.y - downY) < 30) {
                        toggleBars()
                    }
                }
            }
            false
        }

        // 返回键：工具栏展开时先收起，避免误退出
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                if (binding.topBar.isVisible) {
                    toggleBars()
                } else {
                    isEnabled = false
                    onBackPressedDispatcher.onBackPressed()
                }
            }
        })

        // 安全区：正文、工具栏分别避让状态栏/刘海与导航栏
        ViewCompat.setOnApplyWindowInsetsListener(binding.root) { _, insets ->
            val bars = insets.getInsets(
                WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
            )
            statusBarInset = bars.top
            navBarInset = bars.bottom
            horizontalInset = maxOf(bars.left, bars.right)
            binding.topBar.updatePadding(
                left = horizontalInset,
                top = bars.top,
                right = horizontalInset,
            )
            binding.bottomBar.updatePadding(
                left = horizontalInset,
                bottom = bars.bottom,
                right = horizontalInset,
            )
            updateContentInsets()
            insets
        }
        ViewCompat.requestApplyInsets(binding.root)

        renderChapter()
    }

    private fun renderChapter() {
        binding.tvChapterTitle.text = chapters.getOrNull(currentChapter)?.chapterName.orEmpty()
        binding.tvContent.textSize = fontSize
        binding.tvContent.text = loadChapterContent(book, currentChapter)
        binding.tvChapterEnd.text = if (currentChapter >= totalChapters - 1) {
            "— 本章完 · 全书完 —"
        } else {
            "— 本章完 · 轻触进入下一章 —"
        }
        binding.tvProgress.text = "${(currentChapter + 1) * 100 / totalChapters}% · 第${currentChapter + 1}章"
        applyTheme()
    }

    private fun selectChapter(index: Int) {
        currentChapter = index.coerceIn(0, totalChapters - 1)
        renderChapter()
        binding.contentArea.post { binding.contentArea.scrollTo(0, 0) }
    }

    private fun goNextChapter() {
        if (currentChapter >= totalChapters - 1) {
            Toast.makeText(this, "已是最后一章", Toast.LENGTH_SHORT).show()
        } else {
            selectChapter(currentChapter + 1)
        }
    }

    private fun toggleBars() {
        val show = !binding.topBar.isVisible
        binding.topBar.isVisible = show
        binding.bottomBar.isVisible = show
        updateContentInsets()
    }

    /** 工具栏收起时正文延伸到系统栏后面，通过 padding 保证文字不被状态栏/导航栏遮挡 */
    private fun updateContentInsets() {
        val top = if (binding.topBar.isVisible) 0 else statusBarInset
        val bottom = if (binding.bottomBar.isVisible) 0 else navBarInset
        binding.contentArea.updatePadding(
            left = horizontalInset,
            top = top,
            right = horizontalInset,
            bottom = bottom,
        )
    }

    private fun changeFontSize(delta: Int) {
        fontSize = (fontSize + delta * 2).coerceIn(14f, 26f)
        binding.tvContent.textSize = fontSize
        MMKVStore.readerFontSize = fontSize.toInt()
        Toast.makeText(this, "字号 ${fontSize.toInt()}", Toast.LENGTH_SHORT).show()
    }

    private fun cycleTheme() {
        themeIndex = (themeIndex + 1) % themeNames.size
        MMKVStore.readerTheme = themeIndex
        applyTheme()
        Toast.makeText(this, themeNames[themeIndex], Toast.LENGTH_SHORT).show()
    }

    private fun applyTheme() {
        val (bgRes, fgRes) = themeColors[themeIndex]
        val bg = ContextCompat.getColor(this, bgRes)
        val fg = ContextCompat.getColor(this, fgRes)

        binding.root.setBackgroundColor(bg)
        binding.contentArea.setBackgroundColor(bg)
        binding.topBar.setBackgroundColor(bg)
        binding.bottomBar.setBackgroundColor(bg)

        binding.tvBookTitle.setTextColor(fg)
        binding.tvChapterTitle.setTextColor(fg)
        binding.tvChapterAuthor.setTextColor(fg)
        binding.tvContent.setTextColor(fg)
        binding.tvChapterEnd.setTextColor(fg)
        binding.tvProgress.setTextColor(fg)
        listOf(binding.btnCatalog, binding.btnFontMinus, binding.btnFontPlus, binding.btnTheme)
            .forEach { it.setTextColor(fg) }
        binding.btnBack.imageTintList = ColorStateList.valueOf(fg)

        // 夜间黑主题使用白色系统栏图标，其余主题使用深色图标
        val lightIcons = themeIndex == themeNames.lastIndex
        setSystemBarStyle(lightStatusBar = !lightIcons, lightNavBar = !lightIcons)
    }

    private fun showCatalog() {
        val dialog = BottomSheetDialog(this)
        val catalogView = layoutInflater.inflate(R.layout.dialog_catalog, null)
        // 底部目录弹窗避让导航栏，避免最后几章被系统手势条遮挡
        catalogView.setPadding(
            catalogView.paddingLeft,
            catalogView.paddingTop,
            catalogView.paddingRight,
            navBarInset,
        )
        val rv = catalogView.findViewById<androidx.recyclerview.widget.RecyclerView>(R.id.recyclerView)
        rv.layoutManager = androidx.recyclerview.widget.LinearLayoutManager(this)
        rv.adapter = object :
            androidx.recyclerview.widget.RecyclerView.Adapter<androidx.recyclerview.widget.RecyclerView.ViewHolder>() {
            override fun onCreateViewHolder(
                parent: android.view.ViewGroup,
                viewType: Int,
            ): androidx.recyclerview.widget.RecyclerView.ViewHolder {
                val tv = android.widget.TextView(this@ReaderActivity).apply {
                    setPadding(56, 28, 16, 28)
                    textSize = 15f
                    setTextColor(ContextCompat.getColor(this@ReaderActivity, R.color.text_primary))
                }
                return object : androidx.recyclerview.widget.RecyclerView.ViewHolder(tv) {}
            }

            override fun getItemCount(): Int = chapters.size

            override fun onBindViewHolder(
                holder: androidx.recyclerview.widget.RecyclerView.ViewHolder,
                position: Int,
            ) {
                val tv = holder.itemView as android.widget.TextView
                tv.text = chapters[position].chapterName.orEmpty()
                tv.setTextColor(
                    if (position == currentChapter) {
                        ContextCompat.getColor(this@ReaderActivity, R.color.primary)
                    } else {
                        ContextCompat.getColor(this@ReaderActivity, R.color.text_primary)
                    }
                )
                tv.setOnClickListener {
                    dialog.dismiss()
                    selectChapter(position)
                }
            }
        }
        dialog.setContentView(catalogView)
        dialog.window?.let { window ->
            window.statusBarColor = Color.TRANSPARENT
            window.navigationBarColor = Color.TRANSPARENT
            androidx.core.view.WindowInsetsControllerCompat(window, window.decorView)
                .isAppearanceLightNavigationBars = true
        }
        dialog.show()
    }

    /** 音量键翻页（对应原项目阅读页音量键翻页能力） */
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        return when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_DOWN -> {
                selectChapter(currentChapter + 1)
                true
            }
            KeyEvent.KEYCODE_VOLUME_UP -> {
                selectChapter(currentChapter - 1)
                true
            }
            else -> super.onKeyDown(keyCode, event)
        }
    }

    companion object {
        const val EXTRA_BOOK_ID = "extra_book_id"
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_AUTHOR = "extra_author"
        const val EXTRA_CHAPTERS = "extra_chapters"

        private val themeNames = listOf("白色", "羊皮纸", "护眼绿", "夜间黑")
        private val themeColors = listOf(
            R.color.reader_bg_white to R.color.reader_text_white,
            R.color.reader_bg_sepia to R.color.reader_text_sepia,
            R.color.reader_bg_green to R.color.reader_text_green,
            R.color.reader_bg_black to R.color.reader_text_black,
        )
    }
}
