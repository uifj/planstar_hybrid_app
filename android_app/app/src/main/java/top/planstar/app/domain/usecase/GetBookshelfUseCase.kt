package top.planstar.app.domain.usecase

import top.planstar.app.domain.repository.BookRepository

/** 书架数据加载用例（presentation 只依赖用例，不直接依赖仓库实现）。 */
class GetBookshelfUseCase(private val repository: BookRepository) {

    /** 本地缓存书架：同步返回，供首屏立即渲染 */
    fun cached() = repository.cachedBookshelf()

    suspend operator fun invoke(): Result<BookRepository.BookshelfResult> =
        runCatching { repository.fetchBookshelf() }
}
