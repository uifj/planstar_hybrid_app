package com.qidian.demo.domain.model

import com.google.gson.annotations.SerializedName

/**
 * 书籍精简信息。
 *
 * 与原项目 `com.qidian.QDReader.repository.entity.BookInfoItem` 完全一致：
 * 包含原实体全部字段以及 `@SerializedName` 的 alternate 兼容写法
 * （原项目服务端存在 BookId / bookId 两套命名）。
 */
data class BookInfoItem(
    @SerializedName(alternate = ["bookId"], value = "BookId")
    var bookId: Long = 0,
    @SerializedName(alternate = ["bookName"], value = "BookName")
    var bookName: String? = null,
    @SerializedName(alternate = ["authorName"], value = "AuthorName")
    var authorName: String? = null,
    @SerializedName(alternate = ["description", "Desc"], value = "Description")
    var description: String? = null,
    @SerializedName(alternate = ["categoryName"], value = "CategoryName")
    var categoryName: String? = null,
    @SerializedName(alternate = ["bookStatus", "BookStatus"], value = "ActionStatus")
    var bookStatus: String? = null,
    @SerializedName(alternate = ["wordsCount", "WordsCount"], value = "WordCount")
    var wordsCount: Long = 0,
    @SerializedName(alternate = ["bookType"], value = "BookType")
    var bookType: Int = STR_TYPE_TEXT,
    @SerializedName(alternate = ["bookLevel"], value = "BookLevel")
    var BookLevel: Int = 0,
    @SerializedName("StatId")
    var Col: String? = null,
) {
    private companion object {
        const val STR_TYPE_TEXT = 1
    }
}
