import Foundation

/// 网络客户端（对应 Android 侧 OkHttp + Retrofit 的 `ApiClient` / `QdApiService`）。
///
/// 与原项目的分层保持一致：
/// - 统一 Header 注入（Accept / Authorization）
/// - 请求级 + 资源级超时：`timeoutIntervalForResource = 8s` 等价于 OkHttp `callTimeout`，
///   给 DNS 解析兜底，避免书架请求悬挂十几秒一直转圈
/// - 路径风格沿用原项目：书籍详情 `/app/BookDetail`
final class ApiClient {

    /// demo 可用的公版书单数据源（@Url 绝对地址）
    static let bookListURL = "https://gutendex.com/books"

    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURL: String) {
        let normalized = baseURL.hasSuffix("/") ? baseURL : baseURL + "/"
        self.baseURL = URL(string: normalized) ?? URL(string: DemoStore.defaultBaseURL)!
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 6
        configuration.timeoutIntervalForResource = 8
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - 书架 / 书单

    func fetchBooks(page: Int = 1, pageSize: Int = 12) async throws -> GutendexBooksResponse {
        var components = URLComponents(string: ApiClient.bookListURL)
        components?.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize)),
        ]
        guard let url = components?.url else {
            throw ApiError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(to: &request)
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(GutendexBooksResponse.self, from: data)
    }

    // MARK: - 登录

    /// 登录鉴权（demo 走 httpbin 回显，仅验证网络链路是否可用）
    func login(username: String, password: String) async -> Bool {
        do {
            var request = try makeRequest(path: "post", method: "POST")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(LoginRequest(username: username, password: password))
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200..<300).contains(http.statusCode)
        } catch {
            return false
        }
    }

    // MARK: - 书籍详情

    func fetchBookDetail(bookId: Int64) async throws -> ServerResponse<BookDetailItem> {
        var request = try makeRequest(path: "app/BookDetail", method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(["bookId": bookId])
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(ServerResponse<BookDetailItem>.self, from: data)
    }

    // MARK: - 私有

    private func makeRequest(path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw ApiError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        applyHeaders(to: &request)
        return request
    }

    private func applyHeaders(to request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let token = DemoStore.shared.token
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
}

enum ApiError: LocalizedError {
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "请求地址不合法"
        }
    }
}
