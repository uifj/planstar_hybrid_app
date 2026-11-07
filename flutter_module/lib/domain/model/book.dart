/// 书籍领域模型。
///
/// 字段与原项目 `BookItem` 对齐（BookId / BookName / Author / BookCategoryName /
/// Description / WordsCount / BookStatus），便于后续复用原生侧同一套接口数据。
class Book {
  final int bookId;
  final String bookName;
  final String authorName;
  final String categoryName;
  final String description;

  /// 章节总数。
  final int chapterCount;

  /// 总字数，单位「字」。
  final int wordsCount;

  /// "1" 连载 / "2" 完本。
  final String bookStatus;

  /// 评分，0-100。
  final int bookStar;

  /// 封面图地址；本地书单没有封面，允许为空。
  final String? coverUrl;

  /// 语种（如 en / zh），本地书单未标注时为空。
  final String? language;

  const Book({
    required this.bookId,
    required this.bookName,
    required this.authorName,
    required this.categoryName,
    required this.description,
    required this.chapterCount,
    required this.wordsCount,
    required this.bookStatus,
    required this.bookStar,
    this.coverUrl,
    this.language,
  });

  bool get finished => bookStatus == '2';

  /// 字数展示按「万字」取整，与原生侧列表展示口径一致。
  int get wordsInWan => (wordsCount / 10000).round();
}
