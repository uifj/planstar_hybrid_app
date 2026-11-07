package top.planstar.app.data.repository

import top.planstar.app.data.local.MMKVStore
import top.planstar.app.data.remote.PlanstarApiService
import top.planstar.app.data.remote.dto.LoginRequest
import top.planstar.app.domain.model.UserInfo
import top.planstar.app.domain.repository.LoginRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * 登录仓库实现（data 层）。
 *
 * 与原项目登录逻辑一致：
 * 1. 优先发起网络鉴权（demo 走 httpbin 回显）；
 * 2. 网络不可用时回退本地演示账号 demo / 123456；
 * 3. 成功后把 token / 昵称 / userId 写入 MMKV，再由 presentation 通知 Flutter。
 */
class LoginRepositoryImpl(private val api: PlanstarApiService) : LoginRepository {

    override suspend fun login(username: String, password: String): UserInfo =
        withContext(Dispatchers.IO) {
            val networkOk = runCatching { api.login(LoginRequest(username, password)).isSuccessful }
                .getOrDefault(false)

            val accountValid = networkOk || (username == DEMO_ACCOUNT && password == DEMO_PASSWORD)
            if (!accountValid) {
                throw IllegalArgumentException("账号或密码错误（演示账号 demo / 123456）")
            }

            val nickname = if (networkOk) username else "演示用户"
            val user = UserInfo(
                UserId = kotlin.math.abs(username.hashCode()).toLong(),
                UserName = nickname,
            )
            MMKVStore.saveLogin(
                token = "tok_" + System.currentTimeMillis().toString(36),
                nickname = nickname,
                userId = user.UserId,
            )
            user
        }

    override fun logout() {
        MMKVStore.clearLogin()
    }

    override fun isLoggedIn(): Boolean = MMKVStore.token.isNotEmpty()

    override fun currentUser(): UserInfo? =
        if (!isLoggedIn()) {
            null
        } else {
            UserInfo(UserId = MMKVStore.userId, UserName = MMKVStore.nickname)
        }

    companion object {
        private const val DEMO_ACCOUNT = "demo"
        private const val DEMO_PASSWORD = "123456"
    }
}
