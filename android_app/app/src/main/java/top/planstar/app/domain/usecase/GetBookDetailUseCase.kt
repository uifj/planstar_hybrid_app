package top.planstar.app.domain.usecase

import top.planstar.app.domain.model.BookDetailItem
import top.planstar.app.domain.repository.BookRepository

/** 书籍详情用例（对应原项目书籍详情页数据加载）。 */
class GetBookDetailUseCase(private val repository: BookRepository) {

    suspend operator fun invoke(bookId: Long): Result<BookDetailItem?> =
        runCatching { repository.fetchBookDetail(bookId) }
}
