package com.qidian.demo.domain.model

import com.google.gson.annotations.SerializedName

/**
 * 章节。
 *
 * 对齐原项目 `com.qidian.QDReader.repository.entity.Chapter`：
 * 原实体是 Kotlin data class，服务端字段使用短 key（CId/CN/Wds/LF/Price…），
 * 这里保持同样的字段与 key，保证接口数据可直接反序列化。
 */
data class Chapter(
    @SerializedName("CId")
    val cId: Long = 0,
    @SerializedName("CN")
    val chapterName: String? = null,
    @SerializedName("Wds")
    val wds: Int = 0,
    @SerializedName("Price")
    val price: Int = 0,
    @SerializedName("NPrice")
    val nPrice: Int = 0,
    @SerializedName("JuniorPrice")
    val juniorPrice: Int = 0,
    @SerializedName("LF")
    val limitFree: Int = LIMIT_FREE_NOT,
    @SerializedName("IE")
    val isExtend: Int = 0,
    @SerializedName("MTMP")
    val mtmp: Int = 0,
    @SerializedName("AddP")
    val addP: Int? = null,
) {
    /** 是否免费章节（对应阅读页付费角标逻辑） */
    fun isFree(): Boolean = limitFree == LIMIT_FREE_YES || price <= 0

    companion object {
        const val LIMIT_FREE_NOT = 0
        const val LIMIT_FREE_YES = 1
    }
}
