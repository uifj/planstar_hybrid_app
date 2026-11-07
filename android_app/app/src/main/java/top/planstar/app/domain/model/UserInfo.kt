package top.planstar.app.domain.model

import com.google.gson.annotations.SerializedName

/**
 * 用户信息。
 *
 * 字段与 `@SerializedName` 完全对齐原项目
 * `com.qidian.QDReader.repository.entity.UserInfo`。
 */
data class UserInfo(
    @SerializedName("UserId")
    var UserId: Long = 0,
    @SerializedName(alternate = ["NickName"], value = "UserName")
    var UserName: String? = null,
    @SerializedName(alternate = ["UserHeadIcon"], value = "UserIcon")
    var UserIcon: String? = null,
    @SerializedName("FrameId")
    var FrameId: Long = 0,
    @SerializedName("FrameUrl")
    var FrameUrl: String? = null,
    @SerializedName("TitleInfoList")
    var UserTagList: List<UserTag>? = null,
)

/** 用户头衔标签（对应原项目 repository.entity.UserTag） */
data class UserTag(
    @SerializedName("TitleName")
    var titleName: String? = null,
    @SerializedName("TitleId")
    var titleId: Long = 0,
)
