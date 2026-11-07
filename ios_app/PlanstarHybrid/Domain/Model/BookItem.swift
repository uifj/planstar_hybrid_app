import Foundation

/// 书架 / 书单条目。
///
/// 对齐原项目 `com.qidian.QDReader.repository.entity.BookItem`：
/// `CodingKeys` 保持原实体/Parcelable 的 PascalCase 字段名，保证与原项目接口 JSON、
/// 数据库列名可以直接互换。原实体中依赖原生阅读内核的字段（TTS、下载、滚动位置等）
/// 不参与本 demo 的表现层渲染，故未纳入。
struct BookItem: Codable, Equatable {

    var bookId: Int64 = 0
    var bookName: String?
    var author: String?
    var cover: String?
    var bookStatus: String?
    var type: String?
    var categoryId: Int = 0
    var bookCategoryName: String?
    var bookSubCategoryName: String?
    var wordsCount: Int64 = 0
    var chapterCount: Int = 0
    var bookLevel: Int = 0
    var description: String?
    var lastChapterId: Int64 = 0
    var lastChapterName: String?
    var lastChapterTime: Int64 = 0
    var lastChapterTimeStr: String?
    var lastReadChapterName: String?
    var lastReadTime: Int64 = 0
    var lastReadTimeString: String?
    var readChapterId: Int64 = 0
    var readPercent: Float = 0
    var percentString: String?
    var unReadChapter: Int = 0
    var isTop: Int = 0
    var isVip: Int = 0
    var isPublication: Int = 0
    var isJingPai: Int = 0
    var addShelfTime: Int64 = 0
    var addSource: Int = 0
    var status: Int = BookItem.statusOK
    var checkLevelStatus: Int = BookItem.checkLevelStatusValid

    enum CodingKeys: String, CodingKey {
        case bookId = "BookId"
        case bookName = "BookName"
        case author = "Author"
        case cover = "Cover"
        case bookStatus = "BookStatus"
        case type = "Type"
        case categoryId = "CategoryId"
        case bookCategoryName = "BookCategoryName"
        case bookSubCategoryName = "BookSubCategoryName"
        case wordsCount = "WordsCount"
        case chapterCount = "ChapterCount"
        case bookLevel = "BookLevel"
        case description = "Description"
        case lastChapterId = "LastChapterId"
        case lastChapterName = "LastChapterName"
        case lastChapterTime = "LastChapterTime"
        case lastChapterTimeStr = "LastChapterTimeStr"
        case lastReadChapterName = "LastReadChapterName"
        case lastReadTime = "LastReadTime"
        case lastReadTimeString = "LastReadTimeString"
        case readChapterId = "ReadChapterId"
        case readPercent = "ReadPercent"
        case percentString = "PercentString"
        case unReadChapter = "UnReadChapter"
        case isTop = "IsTop"
        case isVip = "IsVip"
        case isPublication = "IsPublication"
        case isJingPai = "IsJingPai"
        case addShelfTime = "AddShelfTime"
        case addSource = "AddSource"
        case status = "Status"
        case checkLevelStatus = "CheckLevelStatus"
    }

    /// 连载 / 完本文案（对应书封下方的状态标签）
    func statusText() -> String {
        bookStatus == BookItem.bookStatusWanben ? "完结" : "连载"
    }

    /// 字数文案（对应书封下方的字数标签）
    func wordsText() -> String {
        if wordsCount >= 10_000 {
            return "\(wordsCount / 10_000)万字"
        }
        return "\(wordsCount)字"
    }

    // MARK: - 原项目常量

    static let bookStatusLianzai = "1"
    static let bookStatusWanben = "2"

    static let typeBook = 1
    static let typeAudio = 2
    static let typeComic = 3

    static let strTypeQD = "qd"
    static let strTypeAudio = "audio"
    static let strTypeComic = "comic"

    static let statusOK = 0
    static let statusAdded = -1
    static let statusMoved = -2
    static let statusDeleted = -3
    static let statusPreviewed = -4
    static let statusLoginMerge = -5

    static let checkLevelStatusValid = 0
    static let checkLevelStatusRemoved = 1
}
