import Foundation

/// 用户信息。
///
/// 字段与 `CodingKeys` 完全对齐原项目
/// `com.qidian.QDReader.repository.entity.UserInfo`。
struct UserInfo: Codable, Equatable {

    var userId: Int64 = 0
    var userName: String?
    var userIcon: String?
    var frameId: Int64 = 0
    var frameUrl: String?
    var userTagList: [UserTag]?

    enum CodingKeys: String, CodingKey {
        case userId = "UserId"
        // 原接口存在 UserName / NickName 两种 key，展示层统一取 userName
        case userName = "UserName"
        case nickName = "NickName"
        case userIcon = "UserIcon"
        case userHeadIcon = "UserHeadIcon"
        case frameId = "FrameId"
        case frameUrl = "FrameUrl"
        case userTagList = "TitleInfoList"
    }

    init() {}

    init(userId: Int64, userName: String?) {
        self.userId = userId
        self.userName = userName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = try container.decodeIfPresent(Int64.self, forKey: .userId) ?? 0
        userName = try container.decodeIfPresent(String.self, forKey: .userName)
            ?? container.decodeIfPresent(String.self, forKey: .nickName)
        userIcon = try container.decodeIfPresent(String.self, forKey: .userIcon)
            ?? container.decodeIfPresent(String.self, forKey: .userHeadIcon)
        frameId = try container.decodeIfPresent(Int64.self, forKey: .frameId) ?? 0
        frameUrl = try container.decodeIfPresent(String.self, forKey: .frameUrl)
        userTagList = try container.decodeIfPresent([UserTag].self, forKey: .userTagList)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        try container.encodeIfPresent(userName, forKey: .userName)
        try container.encodeIfPresent(userIcon, forKey: .userIcon)
        try container.encode(frameId, forKey: .frameId)
        try container.encodeIfPresent(frameUrl, forKey: .frameUrl)
        try container.encodeIfPresent(userTagList, forKey: .userTagList)
    }
}

/// 用户头衔标签（对应原项目 repository.entity.UserTag）
struct UserTag: Codable, Equatable {
    var titleName: String?
    var titleId: Int64 = 0

    enum CodingKeys: String, CodingKey {
        case titleName = "TitleName"
        case titleId = "TitleId"
    }
}
