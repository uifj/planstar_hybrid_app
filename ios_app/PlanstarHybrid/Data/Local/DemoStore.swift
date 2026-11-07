import Foundation

/// 本地存储（对应 Android 侧 MMKV 的登录态与阅读设置持久化）。
///
/// iOS 没有 MMKV，使用 `UserDefaults` 承担同样的键值语义；
/// 键名与 Android MMKVStore 保持一致，便于双端排查同一个用户态问题。
final class DemoStore {

    static let shared = DemoStore()

    /// 默认请求域名（demo 使用 httpbin 回显验证网络链路）
    static let defaultBaseURL = "https://httpbin.org/"

    private enum Key {
        static let token = "token"
        static let nickname = "nickname"
        static let userId = "user_id"
        static let baseURL = "base_url"
        static let readerFontSize = "reader_font_size"
        static let readerTheme = "reader_theme"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var token: String {
        get { defaults.string(forKey: Key.token) ?? "" }
        set { defaults.set(newValue, forKey: Key.token) }
    }

    var nickname: String {
        get { defaults.string(forKey: Key.nickname) ?? "" }
        set { defaults.set(newValue, forKey: Key.nickname) }
    }

    var userId: Int64 {
        get { Int64(defaults.double(forKey: Key.userId)) }
        set { defaults.set(Double(newValue), forKey: Key.userId) }
    }

    var baseUrl: String {
        get { defaults.string(forKey: Key.baseURL) ?? DemoStore.defaultBaseURL }
        set { defaults.set(newValue, forKey: Key.baseURL) }
    }

    /// 阅读字号（对应原项目阅读设置记忆）
    var readerFontSize: Int {
        get {
            let value = defaults.integer(forKey: Key.readerFontSize)
            return value == 0 ? 18 : value
        }
        set { defaults.set(newValue, forKey: Key.readerFontSize) }
    }

    /// 阅读主题索引：0 白色 / 1 羊皮纸 / 2 护眼绿 / 3 夜间黑
    var readerTheme: Int {
        get { defaults.integer(forKey: Key.readerTheme) }
        set { defaults.set(newValue, forKey: Key.readerTheme) }
    }

    var isLoggedIn: Bool {
        !token.isEmpty
    }

    func saveLogin(token: String, nickname: String, userId: Int64) {
        self.token = token
        self.nickname = nickname
        self.userId = userId
    }

    func clearLogin() {
        defaults.removeObject(forKey: Key.token)
        defaults.removeObject(forKey: Key.nickname)
        defaults.removeObject(forKey: Key.userId)
    }
}
