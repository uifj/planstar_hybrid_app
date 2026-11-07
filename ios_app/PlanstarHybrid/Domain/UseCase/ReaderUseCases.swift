import Foundation

/// 加载目录用例
struct LoadChaptersUseCase {

    private let repository: ReaderRepository

    init(repository: ReaderRepository) {
        self.repository = repository
    }

    func callAsFunction(bookId: Int64, total: Int) -> [Chapter] {
        repository.loadChapters(bookId: bookId, total: total)
    }
}

/// 加载章节正文用例
struct LoadChapterContentUseCase {

    private let repository: ReaderRepository

    init(repository: ReaderRepository) {
        self.repository = repository
    }

    func callAsFunction(book: BookItem, chapterIndex: Int) -> String {
        repository.loadChapterContent(book: book, chapterIndex: chapterIndex)
    }
}
