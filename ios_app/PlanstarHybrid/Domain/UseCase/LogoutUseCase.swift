import Foundation

/// 退出登录用例：清空本地登录态，并由调用方通知 Flutter 侧。
struct LogoutUseCase {

    private let repository: LoginRepository

    init(repository: LoginRepository) {
        self.repository = repository
    }

    func callAsFunction() {
        repository.logout()
    }
}
