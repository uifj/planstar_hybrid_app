import Foundation

/// 章节。
///
/// 对齐原项目 `com.qidian.QDReader.repository.entity.Chapter`：
/// 服务端字段使用短 key（CId/CN/Wds/LF/Price…），这里保持同样的 key，
/// 保证接口数据可直接反序列化。
struct Chapter: Codable, Equatable {

    var cId: Int64 = 0
    var chapterName: String?
    var wds: Int = 0
    var price: Int = 0
    var nPrice: Int = 0
    var juniorPrice: Int = 0
    var limitFree: Int = Chapter.limitFreeNot
    var isExtend: Int = 0
    var mtmp: Int = 0
    var addP: Int?

    enum CodingKeys: String, CodingKey {
        case cId = "CId"
        case chapterName = "CN"
        case wds = "Wds"
        case price = "Price"
        case nPrice = "NPrice"
        case juniorPrice = "JuniorPrice"
        case limitFree = "LF"
        case isExtend = "IE"
        case mtmp = "MTMP"
        case addP = "AddP"
    }

    /// 是否免费章节（对应阅读页付费角标逻辑）
    func isFree() -> Bool {
        limitFree == Chapter.limitFreeYes || price <= 0
    }

    static let limitFreeNot = 0
    static let limitFreeYes = 1
}
