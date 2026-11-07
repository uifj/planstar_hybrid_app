import Foundation

/// 服务端统一响应体。
///
/// 与原项目 `com.qidian.QDReader.repository.entity.ServerResponse<T>` 完全一致：
/// Result / Message / Data 三个字段，Result == 0 表示成功。
struct ServerResponse<T: Codable>: Codable {

    var code: Int = -1
    var data: T?
    var message: String?

    var isFromCache: Bool = false

    enum CodingKeys: String, CodingKey {
        case code = "Result"
        case data = "Data"
        case message = "Message"
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(Int.self, forKey: .code) ?? -1
        data = try container.decodeIfPresent(T.self, forKey: .data)
        message = try container.decodeIfPresent(String.self, forKey: .message)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(message, forKey: .message)
    }

    func isSuccess() -> Bool {
        code == 0
    }

    static let keyResult = "Result"
    static let keyMessage = "Message"
    static let keyData = "Data"

    static var resultOK: Int { 0 }
    static var resultError: Int { -1 }
}
