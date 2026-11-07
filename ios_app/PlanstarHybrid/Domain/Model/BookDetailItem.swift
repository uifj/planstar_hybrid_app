import Foundation

/// 书籍详情。
///
/// 对齐原项目 `com.qidian.QDReader.repository.entity.BookDetailItem`，
/// JSON 字段名与原接口返回保持一致。
struct BookDetailItem: Codable, Equatable {

    var bookId: Int64 = 0
    var bookName: String?
    var author: String?
    var authorId: Int64 = 0
    var bookStatus: String?
    var bookStar: Float = 0
    var bookLevel: Int = 0
    var categoryId: Int = 0
    var categoryName: String?
    var subCategoryName: String?
    var description: String?
    var wordsCnt: Int = 0
    var totalChapterCount: Int = 0
    var lastUpdateChapterId: Int = 0
    var lastUpdateChapterName: String?
    var lastChapterUpdateTime: Int64 = 0
    var isVip: Int = 0
    var isPublication: Int = 0
    var isJingPai: Int = 0
    var totalFansCount: Int = 0

    enum CodingKeys: String, CodingKey {
        case bookId = "BookId"
        case bookName = "BookName"
        case author = "Author"
        case authorId = "AuthorId"
        case bookStatus = "BookStatus"
        case bookStar = "BookStar"
        case bookLevel = "BookLevel"
        case categoryId = "CategoryId"
        case categoryName = "CategoryName"
        case subCategoryName = "SubCategoryName"
        case description = "Description"
        case wordsCnt = "WordsCnt"
        case totalChapterCount = "TotalChapterCount"
        case lastUpdateChapterId = "LastUpdateChapterID"
        case lastUpdateChapterName = "LastUpdateChapterName"
        case lastChapterUpdateTime = "LastChapterUpdateTime"
        case isVip = "IsVip"
        case isPublication = "IsPublication"
        case isJingPai = "IsJingPai"
        case totalFansCount = "TotalFansCount"
    }

    func bookStatusText() -> String {
        bookStatus == BookItem.bookStatusWanben ? "已完结" : "连载中"
    }
}
