package com.qidian.demo.domain.repository

import com.qidian.demo.domain.model.BookDetailItem
import com.qidian.demo.domain.model.BookShelfItem

/**
 * 书籍仓库（domain 层契约，对应原项目 repository 模块对外暴露的能力）。
 * 数据来源（网络 / 本地 / 缓存）由 data 层实现决定，domain 不感知。
 */
interface BookRepository {

    /**
     * 本地缓存书架（同步、无 IO 等待）。
     * 首屏先渲染缓存，再异步刷新网络，避免进书架后长时间转圈。
     */
    fun cachedBookshelf(): List<BookShelfItem>

    /** 拉取书架列表；[fromNetwork] 用于界面提示数据来源（对齐 demo 原有行为） */
    suspend fun fetchBookshelf(): BookshelfResult

    /** 书籍详情（对应原项目 /app/BookDetail 接口） */
    suspend fun fetchBookDetail(bookId: Long): BookDetailItem?

    data class BookshelfResult(
        val items: List<BookShelfItem>,
        val fromNetwork: Boolean,
    )
}
