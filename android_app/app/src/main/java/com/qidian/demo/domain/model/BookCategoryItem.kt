package com.qidian.demo.domain.model

import com.google.gson.annotations.SerializedName

/**
 * 书城分类。
 *
 * 字段与 `@SerializedName` 完全对齐原项目
 * `com.qidian.QDReader.repository.entity.BookCategoryItem`。
 */
data class BookCategoryItem(
    @SerializedName("CategoryId")
    var categoryId: Long = 0,
    @SerializedName("CategoryName")
    var categoryName: String? = null,
    @SerializedName("ImageUrl")
    var imageUrl: String? = null,
    @SerializedName("PageId")
    var pageId: Long = 0,
    @SerializedName("SubCategoryId")
    var subCategoryId: Long = 0,
    @SerializedName("SubCategoryName")
    var subCategoryName: String? = null,
    @SerializedName("TotalCount")
    var totalCount: Long = 0,
    @SerializedName("PositionMark")
    var positionMark: String? = null,
    var configId: Long = 0,
    var expiredTime: Long = 0,
)
