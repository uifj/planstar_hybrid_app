import Foundation

/// 阅读仓库实现（data 层）。
///
/// 原项目目录 / 正文来自服务端；本 demo 用确定性算法生成同样的数据结构与正文排版，
/// 保证阅读页渲染逻辑、翻页体验与原项目一致。
final class ReaderRepositoryImpl: ReaderRepository {

    private static let freeChapterCount = 3
    private static let contentParagraphs = 14

    func loadChapters(bookId: Int64, total: Int) -> [Chapter] {
        (1...max(total, 1)).map { index in
            Chapter(
                cId: bookId * 1000 + Int64(index),
                chapterName: "第\(index) 章 章节\(index)",
                wds: 3200,
                price: index <= ReaderRepositoryImpl.freeChapterCount ? 0 : 10,
                limitFree: index <= ReaderRepositoryImpl.freeChapterCount
                    ? Chapter.limitFreeYes
                    : Chapter.limitFreeNot,
                isExtend: index == 1 ? 0 : 1
            )
        }
    }

    func loadChapterContent(book: BookItem, chapterIndex: Int) -> String {
        let intro = [
            "夜色如墨，残月高悬。\(book.bookName ?? "") 的故事，从这里缓缓展开。",
            "少年背负长剑，独自走在荒凉的官道上，脚步声在寂静中格外清晰。",
            "远处传来犬吠，惊起一片宿鸟。他停下脚步，望向天际那一抹微光。",
            "这一路走来，历经磨难无数，却从未有人真正理解他的执着。",
            "江湖路远，人心叵测。可总有一些事，值得他拼尽全力去守护。",
            "风起于青萍之末，浪成于微澜之间。命运的齿轮，正在悄然转动。",
            "他握紧了手中的书卷，仿佛握住了整个世界。",
        ]
        let offset = chapterIndex % intro.count
        var paragraphs: [String] = []
        for index in 0..<ReaderRepositoryImpl.contentParagraphs {
            paragraphs.append(intro[(offset + index) % intro.count])
        }
        return paragraphs.joined(separator: "\n\n")
    }
}
