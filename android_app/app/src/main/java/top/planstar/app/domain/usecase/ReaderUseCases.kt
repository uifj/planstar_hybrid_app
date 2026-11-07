package top.planstar.app.domain.usecase

import top.planstar.app.domain.model.BookItem
import top.planstar.app.domain.model.Chapter
import top.planstar.app.domain.repository.ReaderRepository

/** 加载目录用例 */
class LoadChaptersUseCase(private val repository: ReaderRepository) {

    operator fun invoke(bookId: Long, total: Int): List<Chapter> =
        repository.loadChapters(bookId, total)
}

/** 加载章节正文用例 */
class LoadChapterContentUseCase(private val repository: ReaderRepository) {

    operator fun invoke(book: BookItem, chapterIndex: Int): String =
        repository.loadChapterContent(book, chapterIndex)
}
