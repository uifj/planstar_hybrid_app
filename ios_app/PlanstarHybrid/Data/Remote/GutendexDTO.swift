import Foundation

/// Gutendex 公开书单接口的响应体（demo 的可用网络数据源）。
/// DTO 只存在于 data 层，转换为 domain 的 `BookItem` 后向上传递，避免网络模型污染领域层。
struct GutendexBooksResponse: Codable {
    var count: Int = 0
    var results: [GutendexBook] = []
}

struct GutendexBook: Codable {
    var id: Int64 = 0
    var title: String?
    var authors: [GutendexAuthor] = []
    var downloadCount: Int = 0

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case authors
        case downloadCount = "download_count"
    }
}

struct GutendexAuthor: Codable {
    var name: String?
}

/// 登录请求体（对应原项目账号登录参数）
struct LoginRequest: Codable {
    var username: String
    var password: String
}
