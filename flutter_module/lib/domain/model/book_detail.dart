import 'book.dart';
import 'chapter.dart';

/// 书详情：组合 Book 基础信息，避免再次重复维护书名字段。
class BookDetail {
  final Book book;
  final List<Chapter> chapters;

  const BookDetail({required this.book, required this.chapters});
}
