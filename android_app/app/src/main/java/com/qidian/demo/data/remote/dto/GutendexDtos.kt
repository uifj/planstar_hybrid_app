package com.qidian.demo.data.remote.dto

import com.google.gson.annotations.SerializedName

/**
 * Gutendex 公开书单接口的响应体（demo 的可用网络数据源）。
 * DTO 只存在于 data 层，转换为 domain 的 BookItem 后向上传递，避免网络模型污染领域层。
 */
data class GutendexBooksResponse(
    @SerializedName("count")
    val count: Int = 0,
    @SerializedName("results")
    val results: List<GutendexBook> = emptyList(),
)

data class GutendexBook(
    @SerializedName("id")
    val id: Long = 0,
    @SerializedName("title")
    val title: String? = null,
    @SerializedName("authors")
    val authors: List<GutendexAuthor> = emptyList(),
    @SerializedName("download_count")
    val downloadCount: Int = 0,
)

data class GutendexAuthor(
    @SerializedName("name")
    val name: String? = null,
)

/** 登录请求体（对应原项目账号登录参数） */
data class LoginRequest(
    @SerializedName("username")
    val username: String,
    @SerializedName("password")
    val password: String,
)
