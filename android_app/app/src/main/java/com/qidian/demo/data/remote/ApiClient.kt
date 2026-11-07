package com.qidian.demo.data.remote

import android.content.pm.ApplicationInfo
import com.google.gson.GsonBuilder
import com.qidian.demo.QidianApp
import com.qidian.demo.data.local.MMKVStore
import com.qidian.demo.data.remote.interceptor.HeaderInterceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

/**
 * 网络客户端工厂。
 *
 * 依赖版本对齐原 APK：
 * - OkHttp 3.12.6（原包 `okhttp3.internal.Version.userAgent()` 返回 "okhttp/3.12.6"）
 * - Retrofit 2.9.0 + GsonConverter
 * - 超时、HeaderInterceptor、日志拦截器（仅 debug）与原项目 QDHttpClient 的分层一致
 */
class ApiClient(private val baseUrl: String) {

    private val gson = GsonBuilder().create()

    private val okHttpClient: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(5, TimeUnit.SECONDS)
            .readTimeout(6, TimeUnit.SECONDS)
            .writeTimeout(6, TimeUnit.SECONDS)
            // 总超时：connect/read 超时管不到 DNS 解析，DNS 卡住时请求会悬挂十几秒，
            // 书架就会一直转圈。callTimeout 给整条请求兜底。
            .callTimeout(8, TimeUnit.SECONDS)
            .addInterceptor(
                HeaderInterceptor {
                    buildMap {
                        put("Accept", "application/json")
                        if (MMKVStore.token.isNotEmpty()) {
                            put("Authorization", "Bearer ${MMKVStore.token}")
                        }
                    }
                }
            )
            .apply {
                // 日志拦截器会读取并格式化整个响应体，release 包不挂载
                if (isDebuggable()) {
                    addInterceptor(
                        HttpLoggingInterceptor().apply {
                            level = HttpLoggingInterceptor.Level.BASIC
                        }
                    )
                }
            }
            .build()
    }

    val service: QdApiService by lazy {
        Retrofit.Builder()
            .baseUrl(normalizeBaseUrl(baseUrl))
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
            .create(QdApiService::class.java)
    }

    private fun normalizeBaseUrl(url: String): String = if (url.endsWith("/")) url else "$url/"

    private fun isDebuggable(): Boolean =
        (QidianApp.appContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
}
