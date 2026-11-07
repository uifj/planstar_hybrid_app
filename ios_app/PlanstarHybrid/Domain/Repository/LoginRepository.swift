import Foundation

/// 登录仓库（domain 层契约）。
/// 对应原项目账号模块：登录成功后持久化 token / 用户信息，供原生与 Flutter 共享。
protocol LoginRepository: AnyObject {

    func login(username: String, password: String) async throws -> UserInfo

    func logout()

    func isLoggedIn() -> Bool

    func currentUser() -> UserInfo?
}
