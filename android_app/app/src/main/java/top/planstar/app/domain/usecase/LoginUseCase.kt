package top.planstar.app.domain.usecase

import top.planstar.app.domain.model.UserInfo
import top.planstar.app.domain.repository.LoginRepository

/** 登录用例：调用仓库完成鉴权并持久化登录态。 */
class LoginUseCase(private val repository: LoginRepository) {

    suspend operator fun invoke(username: String, password: String): Result<UserInfo> {
        if (username.isBlank() || password.isBlank()) {
            return Result.failure(IllegalArgumentException("账号或密码不能为空"))
        }
        return runCatching { repository.login(username.trim(), password) }
    }
}
