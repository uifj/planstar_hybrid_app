import Foundation

/// 有声书条目（对应原项目 repository.entity.AudioBookItem 的核心展示字段）。
/// 原实体还包含音质、授权、章节计费等音频业务字段，本 demo 只呈现列表信息。
struct AudioBookItem: Equatable {

    var bookId: Int64 = 0
    var bookName: String?
    var speaker: String?
    var duration: String?
    var cover: String?
}
