import Foundation

/// 登录仓库实现（data 层）。
///
/// 与 Android `LoginRepositoryImpl` 一致：
/// 1. 优先发起网络鉴权（demo 走 httpbin 回显）；
/// 2. 网络不可用时回退本地演示账号 demo / 123456；
/// 3. 成功后把 token / 昵称 / userId 写入本地存储，再由 presentation 通知 Flutter。
final class LoginRepositoryImpl: LoginRepository {

    private static let demoAccount = "demo"
    private static let demoPassword = "123456"

    private let apiClient: ApiClient

    init(apiClient: ApiClient) {
        self.apiClient = apiClient
    }

    func login(username: String, password: String) async throws -> UserInfo {
        let networkOk = await apiClient.login(username: username, password: password)
        let accountValid = networkOk || (username == LoginRepositoryImpl.demoAccount
            && password == LoginRepositoryImpl.demoPassword)
        guard accountValid else {
            throw LoginError.invalidCredentials
        }

        let nickname = networkOk ? username : "演示用户"
        let raw = Int64(truncatingIfNeeded: username.hashValue)
        let userId = raw == Int64.min ? 0 : abs(raw)
        let token = "tok_" + String(Int64(Date().timeIntervalSince1970 * 1000), radix: 36)

        DemoStore.shared.saveLogin(token: token, nickname: nickname, userId: userId)
        return UserInfo(userId: userId, userName: nickname)
    }

    func logout() {
        DemoStore.shared.clearLogin()
    }

    func isLoggedIn() -> Bool {
        DemoStore.shared.isLoggedIn
    }

    func currentUser() -> UserInfo? {
        guard isLoggedIn() else { return nil }
        return UserInfo(userId: DemoStore.shared.userId, userName: DemoStore.shared.nickname)
    }
}
