package com.qidian.demo.data.repository

import com.qidian.demo.data.remote.QdApiService
import com.qidian.demo.data.remote.dto.GutendexBook
import com.qidian.demo.domain.model.BookDetailItem
import com.qidian.demo.domain.model.BookItem
import com.qidian.demo.domain.model.BookShelfItem
import com.qidian.demo.domain.repository.BookRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * 书籍仓库实现（data 层）。
 *
 * 数据处理逻辑与原项目一致：
 * 1. 先走网络（Retrofit 接口），成功则使用服务端数据；
 * 2. 网络异常 / 空数据时回退本地书单（原项目为书架本地缓存）；
 * 3. 网络 DTO 在 data 层转换为 domain 的 [BookItem]，不向上泄漏网络模型。
 */
class BookRepositoryImpl(private val apiProvider: () -> QdApiService) : BookRepository {

    /**
     * 网络栈改为首次真正发请求时才初始化。
     * 这里刻意用 provider 而不是构造参数：`withContext(Dispatchers.IO)` 内首次访问时才会
     * 构建 OkHttpClient / Retrofit / Gson，避免这些初始化落在主线程（进书架时卡一下）。
     */
    private val api: QdApiService by lazy(apiProvider)

    override fun cachedBookshelf(): List<BookShelfItem> = LOCAL_BOOKS.toShelfItems()

    override suspend fun fetchBookshelf(): BookRepository.BookshelfResult =
        withContext(Dispatchers.IO) {
            val remote = runCatching { api.getBookList(BOOK_LIST_URL).results }
                .getOrNull()
                .orEmpty()
                .map { it.toBookItem() }

            if (remote.isNotEmpty()) {
                BookRepository.BookshelfResult(remote.toShelfItems(), fromNetwork = true)
            } else {
                BookRepository.BookshelfResult(LOCAL_BOOKS.toShelfItems(), fromNetwork = false)
            }
        }

    override suspend fun fetchBookDetail(bookId: Long): BookDetailItem? =
        withContext(Dispatchers.IO) {
            runCatching {
                api.getBookDetail(mapOf("bookId" to bookId)).data
            }.getOrNull() ?: LOCAL_BOOKS.firstOrNull { it.BookId == bookId }?.toDetail()
        }

    private fun List<BookItem>.toShelfItems(): List<BookShelfItem> =
        map { BookShelfItem(bookItem = it) }

    private fun GutendexBook.toBookItem(): BookItem = BookItem(
        BookId = id,
        BookName = title ?: "未知书名",
        Author = authors.firstOrNull()?.name ?: "未知作者",
        BookStatus = BookItem.BOOK_STATUS_WANBEN,
        Type = BookItem.STR_TYPE_QD,
        WordsCount = downloadCount.toLong() * 1000,
        BookCategoryName = "公版经典",
        Description = "Gutendex 公版书单 · $downloadCount 次下载",
    )

    private fun BookItem.toDetail(): BookDetailItem = BookDetailItem(
        BookId = BookId,
        BookName = BookName,
        Author = Author,
        BookStatus = BookStatus,
        CategoryName = BookCategoryName,
        Description = Description,
        WordsCnt = WordsCount.toInt(),
        TotalChapterCount = ChapterCount,
        LastUpdateChapterName = LastChapterName,
    )

    companion object {
        private const val BOOK_LIST_URL = "https://gutendex.com/books?page=1&page_size=12"
    }
}

/** 本地书单：网络不可用时的书架数据（与原项目书架缓存结构一致，均为 BookItem 列表） */
internal val LOCAL_BOOKS: List<BookItem> = listOf(
    BookItem(
        BookId = 1013391L, BookName = "元尊", Author = "天蚕土豆",
        BookStatus = BookItem.BOOK_STATUS_WANBEN, CategoryId = 21, BookCategoryName = "玄幻",
        WordsCount = 4830000L, ChapterCount = 3278, BookLevel = 5,
        Description = "天地为炉，万物为铜，阴阳为炭，造化为工。",
        LastChapterName = "第一千三百二十章 大结局",
        LastReadChapterName = "第二百一十章 入圣", ReadPercent = 0.42f, PercentString = "42%",
    ),
    BookItem(
        BookId = 1023384L, BookName = "万相之王", Author = "天蚕土豆",
        BookStatus = BookItem.BOOK_STATUS_LIANZAI, CategoryId = 21, BookCategoryName = "玄幻",
        WordsCount = 3560000L, ChapterCount = 2145, BookLevel = 5,
        Description = "姜青娥：你可知道，什么是万相之王？",
        LastChapterName = "第两千一百四十五章 万相归一",
        LastReadChapterName = "第一百零五章 相术", ReadPercent = 0.18f, PercentString = "18%",
    ),
    BookItem(
        BookId = 1000000L, BookName = "大道朝天", Author = "猫腻",
        BookStatus = BookItem.BOOK_STATUS_WANBEN, CategoryId = 22, BookCategoryName = "仙侠",
        WordsCount = 2360000L, ChapterCount = 1602, BookLevel = 5,
        Description = "青山不改，绿水长流。",
        LastChapterName = "后记", LastReadChapterName = "第四百章 人间", ReadPercent = 0.75f,
    ),
    BookItem(
        BookId = 1010477L, BookName = "赘婿", Author = "愤怒的香蕉",
        BookStatus = BookItem.BOOK_STATUS_WANBEN, CategoryId = 24, BookCategoryName = "历史",
        WordsCount = 4180000L, ChapterCount = 2613, BookLevel = 5,
        Description = "武朝，江宁，苏家。",
        LastChapterName = "第一七五零章 大结局", LastReadChapterName = "第一千章 南下", ReadPercent = 0.55f,
    ),
    BookItem(
        BookId = 1010384L, BookName = "诡秘之主", Author = "爱潜水的乌贼",
        BookStatus = BookItem.BOOK_STATUS_WANBEN, CategoryId = 25, BookCategoryName = "奇幻",
        WordsCount = 4460000L, ChapterCount = 2800, BookLevel = 5,
        Description = "周明瑞在一阵剧烈的疼痛中醒来。",
        LastChapterName = "第一千四百三十章 新的旅程", LastReadChapterName = "第七百章 占卜", ReadPercent = 0.33f,
    ),
    BookItem(
        BookId = 1010495L, BookName = "庆余年", Author = "猫腻",
        BookStatus = BookItem.BOOK_STATUS_WANBEN, CategoryId = 24, BookCategoryName = "历史",
        WordsCount = 3060000L, ChapterCount = 2100, BookLevel = 5,
        Description = "澹州港，有海风，也有少年。",
        LastChapterName = "后记 二十年后", LastReadChapterName = "第三百章 京都", ReadPercent = 0.88f,
    ),
    BookItem(
        BookId = 1028167L, BookName = "夜的命名术", Author = "会说话的肘子",
        BookStatus = BookItem.BOOK_STATUS_WANBEN, CategoryId = 21, BookCategoryName = "玄幻",
        WordsCount = 2080000L, ChapterCount = 1180, BookLevel = 5,
        Description = "如果有一天，你发现自己可以隐身。",
        LastChapterName = "第一千一百八十章 夜的命名", LastReadChapterName = "第五百零二章 潜伏",
        ReadPercent = 0.61f,
    ),
    BookItem(
        BookId = 1027012L, BookName = "大奉打更人", Author = "卖报小郎君",
        BookStatus = BookItem.BOOK_STATUS_WANBEN, CategoryId = 22, BookCategoryName = "仙侠",
        WordsCount = 3300000L, ChapterCount = 1902, BookLevel = 5,
        Description = "人生何处不青山。",
        LastChapterName = "第一千九百零二章 大结局", LastReadChapterName = "第六百章 打更人",
        ReadPercent = 0.29f,
    ),
    BookItem(
        BookId = 1009735L, BookName = "凡人修仙传", Author = "忘语",
        BookStatus = BookItem.BOOK_STATUS_WANBEN, CategoryId = 22, BookCategoryName = "仙侠",
        WordsCount = 7450000L, ChapterCount = 4362, BookLevel = 5,
        Description = "一个普通山村小子，偶然下进入到当地江湖小门派。",
        LastChapterName = "第四千三百六十二章 仙界", LastReadChapterName = "第一千章 筑基",
        ReadPercent = 0.12f,
    ),
)
