import Foundation

/// 书籍详情用例（对应原项目书籍详情页数据加载）。
struct GetBookDetailUseCase {

    private let repository: BookRepository

    init(repository: BookRepository) {
        self.repository = repository
    }

    func callAsFunction(bookId: Int64) async -> BookDetailItem? {
        await repository.fetchBookDetail(bookId: bookId)
    }
}
