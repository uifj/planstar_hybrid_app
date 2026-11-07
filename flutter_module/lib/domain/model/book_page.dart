import 'book.dart';

/// 分页结果：hasMore 由数据源决定，UI 不需要再猜「是否还有下一页」。
class BookPage {
  final List<Book> items;
  final int page;
  final bool hasMore;

  const BookPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });
}
