import Foundation

/// 登录用例：调用仓库完成鉴权并持久化登录态。
struct LoginUseCase {

    private let repository: LoginRepository

    init(repository: LoginRepository) {
        self.repository = repository
    }

    func callAsFunction(username: String, password: String) async throws -> UserInfo {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else {
            throw LoginError.emptyInput
        }
        return try await repository.login(
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
    }
}

enum LoginError: LocalizedError {
    case emptyInput
    case invalidCredentials

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "账号或密码不能为空"
        case .invalidCredentials:
            return "账号或密码错误（演示账号 demo / 123456）"
        }
    }
}
