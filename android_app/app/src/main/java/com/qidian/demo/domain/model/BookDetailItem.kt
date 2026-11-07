package com.qidian.demo.domain.model

import com.google.gson.annotations.SerializedName

/**
 * 书籍详情。
 *
 * 对齐原项目 `com.qidian.QDReader.repository.entity.BookDetailItem`：
 * 原实体字段为包内可见 + getter 形式，这里以 Kotlin 只读属性表达，
 * JSON 字段名与原接口返回保持一致。
 */
data class BookDetailItem(
    @SerializedName("BookId")
    val BookId: Long = 0,
    @SerializedName("BookName")
    val BookName: String? = null,
    @SerializedName("Author")
    val Author: String? = null,
    @SerializedName("AuthorId")
    val AuthorId: Long = 0,
    @SerializedName("BookStatus")
    val BookStatus: String? = null,
    @SerializedName("BookStar")
    val BookStar: Float = 0f,
    @SerializedName("BookLevel")
    val BookLevel: Int = 0,
    @SerializedName("CategoryId")
    val CategoryId: Int = 0,
    @SerializedName("CategoryName")
    val CategoryName: String? = null,
    @SerializedName("SubCategoryName")
    val SubCategoryName: String? = null,
    @SerializedName("Description")
    val Description: String? = null,
    @SerializedName("WordsCnt")
    val WordsCnt: Int = 0,
    @SerializedName("TotalChapterCount")
    val TotalChapterCount: Int = 0,
    @SerializedName("LastUpdateChapterID")
    val LastUpdateChapterID: Int = 0,
    @SerializedName("LastUpdateChapterName")
    val LastUpdateChapterName: String? = null,
    @SerializedName("LastChapterUpdateTime")
    val LastChapterUpdateTime: Long = 0,
    @SerializedName("IsVip")
    val IsVip: Int = 0,
    @SerializedName("IsPublication")
    val IsPublication: Int = 0,
    @SerializedName("IsJingPai")
    val IsJingPai: Int = 0,
    @SerializedName("TotalFansCount")
    val TotalFansCount: Int = 0,
) {
    fun getBookStatusText(): String =
        if (BookStatus == BookItem.BOOK_STATUS_WANBEN) "已完结" else "连载中"
}
