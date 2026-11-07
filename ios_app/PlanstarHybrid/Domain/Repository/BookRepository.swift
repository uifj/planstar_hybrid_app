import Foundation

/// 书架结果：`fromNetwork` 用于界面提示数据来源（对齐 Android `BookRepository.BookshelfResult`）。
struct BookshelfResult {
    let items: [BookShelfItem]
    let fromNetwork: Bool
}

/// 书籍仓库（domain 层契约）。
///
/// 数据来源（网络 / 本地 / 缓存）由 data 层实现决定，domain 不感知。
protocol BookRepository: AnyObject {

    /// 本地缓存书架（同步、无 IO 等待）。
    /// 首屏先渲染缓存，再异步刷新网络，避免进书架后长时间转圈。
    func cachedBookshelf() -> [BookShelfItem]

    /// 拉取书架列表
    func fetchBookshelf() async -> BookshelfResult

    /// 书籍详情（对应原项目 /app/BookDetail 接口）
    func fetchBookDetail(bookId: Int64) async -> BookDetailItem?
}
