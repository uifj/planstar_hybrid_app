package com.qidian.demo.data.repository

import com.qidian.demo.domain.model.BookItem
import com.qidian.demo.domain.model.Chapter
import com.qidian.demo.domain.repository.ReaderRepository

/**
 * 阅读仓库实现（data 层）。
 * 原项目目录 / 正文来自服务端；demo 用确定性算法生成同样的数据结构与正文排版，
 * 保证阅读页渲染逻辑、翻页体验与原项目一致。
 */
class ReaderRepositoryImpl : ReaderRepository {

    override fun loadChapters(bookId: Long, total: Int): List<Chapter> =
        (1..total).map { index ->
            Chapter(
                cId = bookId * 1000 + index,
                chapterName = "第$index 章 章节$index",
                wds = 3200,
                price = if (index <= FREE_CHAPTER_COUNT) 0 else 10,
                limitFree = if (index <= FREE_CHAPTER_COUNT) {
                    Chapter.LIMIT_FREE_YES
                } else {
                    Chapter.LIMIT_FREE_NOT
                },
                isExtend = if (index == 1) 0 else 1,
            )
        }

    override fun loadChapterContent(book: BookItem, chapterIndex: Int): String {
        val intro = listOf(
            "夜色如墨，残月高悬。${book.BookName.orEmpty()} 的故事，从这里缓缓展开。",
            "少年背负长剑，独自走在荒凉的官道上，脚步声在寂静中格外清晰。",
            "远处传来犬吠，惊起一片宿鸟。他停下脚步，望向天际那一抹微光。",
            "这一路走来，历经磨难无数，却从未有人真正理解他的执着。",
            "江湖路远，人心叵测。可总有一些事，值得他拼尽全力去守护。",
            "风起于青萍之末，浪成于微澜之间。命运的齿轮，正在悄然转动。",
            "他握紧了手中的书卷，仿佛握住了整个世界。",
        )
        val sb = StringBuilder()
        val offset = chapterIndex % intro.size
        for (i in 0 until CONTENT_PARAGRAPHS) {
            sb.append(intro[(offset + i) % intro.size]).append("\n\n")
        }
        return sb.toString()
    }

    private companion object {
        const val FREE_CHAPTER_COUNT = 3
        const val CONTENT_PARAGRAPHS = 14
    }
}
