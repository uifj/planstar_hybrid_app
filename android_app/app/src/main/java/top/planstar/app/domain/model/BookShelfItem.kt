package top.planstar.app.domain.model

/**
 * 书架列表项包装。
 *
 * 对齐原项目 `com.qidian.QDReader.repository.entity.BookShelfItem`：
 * 原项目书架适配器接收的是 BookShelfItem（可承载分组、活动卡片、推荐位），
 * 普通书籍项通过 [bookItem] 取到 BookItem。
 */
data class BookShelfItem(
    var bookItem: BookItem? = null,
    var groupName: String = "",
    var mType: Int = TYPE_DEFAULT,
    var mIsChecked: Boolean = false,
    var lastUpdateTime: Long = 0,
    var showUpdateNotice: Boolean = false,
) {
    companion object {
        const val TYPE_DEFAULT = 0
        const val TYPE_LOCAL = 1
        const val TYPE_GROUP = 2
        const val TYPE_EMPTY = 3
        const val TYPE_FOOTER = 4
        const val TYPE_RECOMMEND_HEADER = 5
        const val TYPE_RECOMMEND_BOOK = 6
    }
}
