package com.qidian.demo.domain.model

import com.google.gson.annotations.SerializedName

/**
 * 书架 / 书单条目。
 *
 * 对齐原项目 `com.qidian.QDReader.repository.entity.BookItem`：
 * 字段名、常量名与原实体保持一致（PascalCase），保证与原项目的 JSON 字段、
 * 数据库列名、Parcelable 语义可以直接互换。
 *
 * 原实体还包含大量阅读进度 / TTS / 下载等原生阅读引擎专用字段
 * （TTSPlayOffset、ScrollToExtra、FilePath…），这些字段依赖原项目的阅读内核，
 * 在本 demo 中不参与表现层渲染，因此未纳入。
 */
data class BookItem(
    @SerializedName("BookId")
    var BookId: Long = 0,
    @SerializedName("BookName")
    var BookName: String? = null,
    @SerializedName("Author")
    var Author: String? = null,
    @SerializedName("Cover")
    var Cover: String? = null,
    @SerializedName("BookStatus")
    var BookStatus: String? = null,
    @SerializedName("Type")
    var Type: String? = null,
    @SerializedName("CategoryId")
    var CategoryId: Int = 0,
    @SerializedName("BookCategoryName")
    var BookCategoryName: String? = null,
    @SerializedName("BookSubCategoryName")
    var BookSubCategoryName: String? = null,
    @SerializedName("WordsCount")
    var WordsCount: Long = 0,
    @SerializedName("ChapterCount")
    var ChapterCount: Int = 0,
    @SerializedName("BookLevel")
    var BookLevel: Int = 0,
    @SerializedName("Description")
    var Description: String? = null,
    @SerializedName("LastChapterId")
    var LastChapterId: Long = 0,
    @SerializedName("LastChapterName")
    var LastChapterName: String? = null,
    @SerializedName("LastChapterTime")
    var LastChapterTime: Long = 0,
    @SerializedName("LastChapterTimeStr")
    var LastChapterTimeStr: String? = null,
    @SerializedName("LastReadChapterName")
    var LastReadChapterName: String? = null,
    @SerializedName("LastReadTime")
    var LastReadTime: Long = 0,
    @SerializedName("LastReadTimeString")
    var LastReadTimeString: String? = null,
    @SerializedName("ReadChapterId")
    var ReadChapterId: Long = 0,
    @SerializedName("ReadPercent")
    var ReadPercent: Float = 0f,
    @SerializedName("PercentString")
    var PercentString: String? = null,
    @SerializedName("UnReadChapter")
    var UnReadChapter: Int = 0,
    @SerializedName("IsTop")
    var IsTop: Int = 0,
    @SerializedName("IsVip")
    var IsVip: Int = 0,
    @SerializedName("IsPublication")
    var IsPublication: Int = 0,
    @SerializedName("IsJingPai")
    var IsJingPai: Int = 0,
    @SerializedName("AddShelfTime")
    var AddShelfTime: Long = 0,
    @SerializedName("AddSource")
    var AddSource: Int = 0,
    @SerializedName("Status")
    var Status: Int = STATUS_OK,
    @SerializedName("CheckLevelStatus")
    var CheckLevelStatus: Int = CHECK_LEVEL_STATUS_VALID,
) {

    /** 连载 / 完本文案（对应书封下方的状态标签） */
    fun statusText(): String = if (BookStatus == BOOK_STATUS_WANBEN) "完结" else "连载"

    /** 字数文案（对应书封下方的字数标签） */
    fun wordsText(): String =
        if (WordsCount >= 10000L) "${WordsCount / 10000}万字" else "${WordsCount}字"

    companion object {
        const val BOOK_STATUS_LIANZAI = "1"
        const val BOOK_STATUS_WANBEN = "2"

        const val TYPE_BOOK = 1
        const val TYPE_AUDIO = 2
        const val TYPE_COMIC = 3

        const val STR_TYPE_QD = "qd"
        const val STR_TYPE_AUDIO = "audio"
        const val STR_TYPE_COMIC = "comic"

        const val STATUS_OK = 0
        const val STATUS_ADDED = -1
        const val STATUS_MOVED = -2
        const val STATUS_DELETED = -3
        const val STATUS_PREVIEWED = -4
        const val STATUS_LOGIN_MERGE = -5

        const val CHECK_LEVEL_STATUS_VALID = 0
        const val CHECK_LEVEL_STATUS_REMOVED = 1
    }
}
