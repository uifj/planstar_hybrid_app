package top.planstar.app.domain.usecase

import top.planstar.app.domain.repository.LoginRepository

/** 退出登录用例：清空本地登录态，并由调用方通知 Flutter 侧。 */
class LogoutUseCase(private val repository: LoginRepository) {

    operator fun invoke() = repository.logout()
}
