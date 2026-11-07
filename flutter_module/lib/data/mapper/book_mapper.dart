import '../../domain/model/book.dart';
import '../../domain/model/book_detail.dart';
import '../../domain/model/chapter.dart';
import '../remote/gutendex_dto.dart';

/// DTO → 领域模型。
///
/// 接口缺字段时在这里统一兜底，避免把「未知书名」这类展示逻辑散落到页面。
class BookMapper {
  static const String _unknownTitle = '未知书名';
  static const String _unknownAuthor = '未知作者';

  /// Gutendex 没有分类字段，公版书统一归入「文学」。
  static const String _defaultCategory = '文学';

  /// 接口不返回字数与章节数：按下载量粗换算，保证列表里的
  /// 「x 万字 / y 章」有合理量级，仅用于展示。
  static const int _wordsPerDownload = 50;
  static const int _wordsPerChapter = 3000;

  static const int _maxChapters = 30;

  Book toBook(GutendexBookDto dto) {
    final title = dto.title.trim().isEmpty ? _unknownTitle : dto.title.trim();
    final author = dto.authorName.trim().isEmpty
        ? _unknownAuthor
        : dto.authorName.trim();
    final downloads = dto.downloadCount < 1 ? 1 : dto.downloadCount;
    final wordsCount = downloads * _wordsPerDownload;
    final chapterCount = (wordsCount / _wordsPerChapter).ceil();
    final cover = dto.formats['image/jpeg'];

    return Book(
      bookId: dto.id,
      bookName: title,
      authorName: author,
      categoryName: _defaultCategory,
      description: '《$title》为古登堡计划收录的公版作品，可在原生阅读页查看内容。',
      chapterCount: chapterCount,
      wordsCount: wordsCount,
      // 公版作品按完本处理；接口没有连载状态
      bookStatus: '2',
      // 用下载量取模映射到 80-99 分，保证同一本书每次评分一致
      bookStar: 80 + downloads % 20,
      coverUrl: cover == null || cover.isEmpty ? null : cover,
      language: dto.language,
    );
  }

  BookDetail toDetail(GutendexBookDto dto) {
    final book = toBook(dto);
    final count = book.chapterCount > _maxChapters
        ? _maxChapters
        : book.chapterCount;
    return BookDetail(
      book: book,
      chapters: List.generate(
        count,
        (index) =>
            Chapter(index: index + 1, title: '第${index + 1}章 章节${index + 1}'),
      ),
    );
  }
}
