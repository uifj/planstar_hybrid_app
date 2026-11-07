import '../model/book_detail.dart';
import '../model/book_page.dart';

/// 书籍仓库接口：presentation 只依赖抽象，方便替换数据源与后续单测。
abstract class BookRepository {
  Future<BookPage> fetchBooks({int page = 1});

  Future<BookPage> searchBooks({required String query, int page = 1});

  Future<BookDetail> fetchBookDetail({required int bookId});
}
