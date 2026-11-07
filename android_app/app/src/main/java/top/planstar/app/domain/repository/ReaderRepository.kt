package top.planstar.app.domain.repository

import top.planstar.app.domain.model.BookItem
import top.planstar.app.domain.model.Chapter

/**
 * 阅读仓库（domain 层契约）。
 * 对应原项目目录（QDDirectoryActivity）与阅读（QDReaderActivity）的数据获取逻辑。
 */
interface ReaderRepository {

    /** 加载目录：原项目由服务端返回章节列表，demo 以固定章节数模拟 */
    fun loadChapters(bookId: Long, total: Int): List<Chapter>

    /** 加载指定序号章节的正文（0 基） */
    fun loadChapterContent(book: BookItem, chapterIndex: Int): String
}
