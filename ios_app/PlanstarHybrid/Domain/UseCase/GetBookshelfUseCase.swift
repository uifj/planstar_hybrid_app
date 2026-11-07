import Foundation

/// 书架数据加载用例（presentation 只依赖用例，不直接依赖仓库实现）。
struct GetBookshelfUseCase {

    private let repository: BookRepository

    init(repository: BookRepository) {
        self.repository = repository
    }

    /// 本地缓存书架：同步返回，供首屏立即渲染
    func cached() -> [BookShelfItem] {
        repository.cachedBookshelf()
    }

    /// 异步刷新书架（网络优先，失败回退本地）
    func callAsFunction() async -> BookshelfResult {
        await repository.fetchBookshelf()
    }
}
