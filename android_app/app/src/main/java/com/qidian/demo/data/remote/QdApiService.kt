package com.qidian.demo.data.remote

import com.qidian.demo.data.remote.dto.GutendexBooksResponse
import com.qidian.demo.data.remote.dto.LoginRequest
import com.qidian.demo.domain.model.BookCategoryItem
import com.qidian.demo.domain.model.BookDetailItem
import com.qidian.demo.domain.model.ServerResponse
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Query
import retrofit2.http.Url

/**
 * 网络接口定义（Retrofit 2.9.0）。
 *
 * 路径风格与原项目保持一致：
 * - 书籍详情：原项目 `/app/BookDetail`
 * - 分类：`/argus/api/v1/...`
 * demo 运行环境无法访问原业务网关，书架数据改用 Gutendex 公开接口（@Url 指定绝对地址），
 * 但请求方式、响应包装（ServerResponse）、拦截器链与原项目一致。
 */
interface QdApiService {

    /** 书架 / 书单（绝对地址，便于切换到可用的演示数据源） */
    @GET
    suspend fun getBookList(
        @Url url: String,
        @Query("page") page: Int = 1,
        @Query("page_size") pageSize: Int = 12,
    ): GutendexBooksResponse

    /** 书籍详情（原项目路径 /app/BookDetail） */
    @POST("app/BookDetail")
    suspend fun getBookDetail(@Body params: Map<String, @JvmSuppressWildcards Any>): ServerResponse<BookDetailItem>

    /** 书城分类（原项目 argus 网关） */
    @POST("argus/api/v1/bookstore/category")
    suspend fun getCategoryList(@Body params: Map<String, @JvmSuppressWildcards Any>): ServerResponse<List<BookCategoryItem>>

    /** 登录（httpbin 回显，用于验证网络链路是否可用） */
    @POST("post")
    suspend fun login(@Body body: LoginRequest): Response<ResponseBody>
}
