import Foundation

/// 书架列表项包装。
///
/// 对齐原项目 `com.qidian.QDReader.repository.entity.BookShelfItem`：
/// 书架适配器接收的是 BookShelfItem（可承载分组、活动卡片、推荐位），
/// 普通书籍项通过 `bookItem` 取到 BookItem。
struct BookShelfItem: Equatable {

    var bookItem: BookItem?
    var groupName: String = ""
    var type: Int = BookShelfItem.typeDefault
    var isChecked: Bool = false
    var lastUpdateTime: Int64 = 0
    var showUpdateNotice: Bool = false

    static let typeDefault = 0
    static let typeLocal = 1
    static let typeGroup = 2
    static let typeEmpty = 3
    static let typeFooter = 4
    static let typeRecommendHeader = 5
    static let typeRecommendBook = 6
}
