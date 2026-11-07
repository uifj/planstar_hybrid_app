package top.planstar.app.data.remote.interceptor

import okhttp3.Interceptor
import okhttp3.Response

/**
 * 公共请求头拦截器。
 *
 * 对齐原项目 `framework.network.common.search`（HeaderInterceptor）：
 * 由外部提供 header 映射（原项目由账号/设备/版本模块动态生成），
 * 拦截器只负责过滤空 key / 空 value 后统一注入。
 */
class HeaderInterceptor(
    private val headerProvider: () -> Map<String, String>,
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val builder = chain.request().newBuilder()
        headerProvider().forEach { (key, value) ->
            if (key.isNotBlank() && value.isNotBlank()) {
                builder.addHeader(key, value)
            }
        }
        return chain.proceed(builder.build())
    }
}
