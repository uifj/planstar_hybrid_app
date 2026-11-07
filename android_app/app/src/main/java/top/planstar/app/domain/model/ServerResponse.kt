package top.planstar.app.domain.model

import com.google.gson.annotations.SerializedName

/**
 * 服务端统一响应体。
 *
 * 与原项目 `com.qidian.QDReader.repository.entity.ServerResponse<T>` 完全一致：
 * Result / Message / Data 三个字段，Result == 0 表示成功。
 */
data class ServerResponse<T>(
    @SerializedName("Result")
    var code: Int = RESULT_ERROR,
    @SerializedName(alternate = ["TopBookMarkList"], value = "Data")
    var data: T? = null,
    @SerializedName("Message")
    var message: String? = null,
) {
    var isFromCache: Boolean = false

    fun isSuccess(): Boolean = code == RESULT_OK

    companion object {
        const val KEY_RESULT = "Result"
        const val KEY_MESSAGE = "Message"
        const val KEY_DATA = "Data"

        const val RESULT_OK = 0
        const val RESULT_ERROR = -1
    }
}
