import Foundation

/// 书籍仓库实现（data 层）。
///
/// 数据处理逻辑与 Android `BookRepositoryImpl` 一致：
/// 1. 先走网络，成功则使用服务端数据；
/// 2. 网络异常 / 空数据时回退本地书单；
/// 3. 网络 DTO 在 data 层转换为 domain 的 `BookItem`，不向上泄漏网络模型。
final class BookRepositoryImpl: BookRepository {

    private let apiClient: ApiClient

    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }

    func cachedBookshelf() -> [BookShelfItem] {
        BookRepositoryImpl.localBooks.map { BookShelfItem(bookItem: $0) }
    }

    func fetchBookshelf() async -> BookshelfResult {
        let remote = (try? await apiClient.fetchBooks(page: 1, pageSize: 12))?
            .results
            .map(BookRepositoryImpl.toBookItem) ?? []

        if !remote.isEmpty {
            return BookshelfResult(
                items: remote.map { BookShelfItem(bookItem: $0) },
                fromNetwork: true
            )
        }
        return BookshelfResult(items: cachedBookshelf(), fromNetwork: false)
    }

    func fetchBookDetail(bookId: Int64) async -> BookDetailItem? {
        if let response = try? await apiClient.fetchBookDetail(bookId: bookId),
           let detail = response.data {
            return detail
        }
        return BookRepositoryImpl.localBooks
            .first { $0.bookId == bookId }
            .map(BookRepositoryImpl.toDetail)
    }

    // MARK: - DTO / model 转换

    private static func toBookItem(_ book: GutendexBook) -> BookItem {
        BookItem(
            bookId: book.id,
            bookName: book.title ?? "未知书名",
            author: book.authors.first?.name ?? "未知作者",
            bookStatus: BookItem.bookStatusWanben,
            type: BookItem.strTypeQD,
            wordsCount: Int64(book.downloadCount) * 1000,
            bookCategoryName: "公版经典",
            description: "Gutendex 公版书单 · \(book.downloadCount) 次下载"
        )
    }

    private static func toDetail(_ book: BookItem) -> BookDetailItem {
        BookDetailItem(
            bookId: book.bookId,
            bookName: book.bookName,
            author: book.author,
            bookStatus: book.bookStatus,
            categoryName: book.bookCategoryName,
            description: book.description,
            wordsCnt: Int(book.wordsCount),
            totalChapterCount: book.chapterCount,
            lastUpdateChapterName: book.lastChapterName
        )
    }

    // MARK: - 本地书单（网络不可用时的书架数据）

    static let localBooks: [BookItem] = [
        BookItem(
            bookId: 1_013_391, bookName: "元尊", author: "天蚕土豆",
            bookStatus: BookItem.bookStatusWanben, categoryId: 21, bookCategoryName: "玄幻",
            wordsCount: 4_830_000, chapterCount: 3278, bookLevel: 5,
            description: "天地为炉，万物为铜，阴阳为炭，造化为工。",
            lastChapterName: "第一千三百二十章 大结局",
            lastReadChapterName: "第二百一十章 入圣",
            readPercent: 0.42, percentString: "42%"
        ),
        BookItem(
            bookId: 1_023_384, bookName: "万相之王", author: "天蚕土豆",
            bookStatus: BookItem.bookStatusLianzai, categoryId: 21, bookCategoryName: "玄幻",
            wordsCount: 3_560_000, chapterCount: 2145, bookLevel: 5,
            description: "姜青娥：你可知道，什么是万相之王？",
            lastChapterName: "第两千一百四十五章 万相归一",
            lastReadChapterName: "第一百零五章 相术",
            readPercent: 0.18, percentString: "18%"
        ),
        BookItem(
            bookId: 1_000_000, bookName: "大道朝天", author: "猫腻",
            bookStatus: BookItem.bookStatusWanben, categoryId: 22, bookCategoryName: "仙侠",
            wordsCount: 2_360_000, chapterCount: 1602, bookLevel: 5,
            description: "青山不改，绿水长流。",
            lastChapterName: "后记", lastReadChapterName: "第四百章 人间", readPercent: 0.75
        ),
        BookItem(
            bookId: 1_010_477, bookName: "赘婿", author: "愤怒的香蕉",
            bookStatus: BookItem.bookStatusWanben, categoryId: 24, bookCategoryName: "历史",
            wordsCount: 4_180_000, chapterCount: 2613, bookLevel: 5,
            description: "武朝，江宁，苏家。",
            lastChapterName: "第一七五零章 大结局", lastReadChapterName: "第一千章 南下",
            readPercent: 0.55
        ),
        BookItem(
            bookId: 1_010_384, bookName: "诡秘之主", author: "爱潜水的乌贼",
            bookStatus: BookItem.bookStatusWanben, categoryId: 25, bookCategoryName: "奇幻",
            wordsCount: 4_460_000, chapterCount: 2800, bookLevel: 5,
            description: "周明瑞在一阵剧烈的疼痛中醒来。",
            lastChapterName: "第一千四百三十章 新的旅程", lastReadChapterName: "第七百章 占卜",
            readPercent: 0.33
        ),
        BookItem(
            bookId: 1_010_495, bookName: "庆余年", author: "猫腻",
            bookStatus: BookItem.bookStatusWanben, categoryId: 24, bookCategoryName: "历史",
            wordsCount: 3_060_000, chapterCount: 2100, bookLevel: 5,
            description: "澹州港，有海风，也有少年。",
            lastChapterName: "后记 二十年后", lastReadChapterName: "第三百章 京都",
            readPercent: 0.88
        ),
        BookItem(
            bookId: 1_028_167, bookName: "夜的命名术", author: "会说话的肘子",
            bookStatus: BookItem.bookStatusWanben, categoryId: 21, bookCategoryName: "玄幻",
            wordsCount: 2_080_000, chapterCount: 1180, bookLevel: 5,
            description: "如果有一天，你发现自己可以隐身。",
            lastChapterName: "第一千一百八十章 夜的命名", lastReadChapterName: "第五百零二章 潜伏",
            readPercent: 0.61
        ),
        BookItem(
            bookId: 1_027_012, bookName: "大奉打更人", author: "卖报小郎君",
            bookStatus: BookItem.bookStatusWanben, categoryId: 22, bookCategoryName: "仙侠",
            wordsCount: 3_300_000, chapterCount: 1902, bookLevel: 5,
            description: "人生何处不青山。",
            lastChapterName: "第一千九百零二章 大结局", lastReadChapterName: "第六百章 打更人",
            readPercent: 0.29
        ),
        BookItem(
            bookId: 1_009_735, bookName: "凡人修仙传", author: "忘语",
            bookStatus: BookItem.bookStatusWanben, categoryId: 22, bookCategoryName: "仙侠",
            wordsCount: 7_450_000, chapterCount: 4362, bookLevel: 5,
            description: "一个普通山村小子，偶然下进入到当地江湖小门派。",
            lastChapterName: "第四千三百六十二章 仙界", lastReadChapterName: "第一千章 筑基",
            readPercent: 0.12
        ),
    ]
}
