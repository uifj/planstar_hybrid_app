import Foundation

/// 阅读仓库（domain 层契约）。
/// 对应原项目目录（QDDirectoryActivity）与阅读（QDReaderActivity）的数据获取逻辑。
protocol ReaderRepository: AnyObject {

    /// 加载目录：原项目由服务端返回章节列表，本 demo 以固定章节数模拟
    func loadChapters(bookId: Int64, total: Int) -> [Chapter]

    /// 加载指定序号章节的正文（0 基）
    func loadChapterContent(book: BookItem, chapterIndex: Int) -> String
}
