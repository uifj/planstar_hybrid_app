package top.planstar.app.domain.repository

import top.planstar.app.domain.model.UserInfo

/**
 * 登录仓库（domain 层契约）。
 * 对应原项目账号模块：登录成功后持久化 token / 用户信息，供原生与 Flutter 共享。
 */
interface LoginRepository {

    suspend fun login(username: String, password: String): UserInfo

    fun logout()

    fun isLoggedIn(): Boolean

    fun currentUser(): UserInfo?
}
