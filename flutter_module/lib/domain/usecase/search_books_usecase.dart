import '../model/book_page.dart';
import '../repository/book_repository.dart';

/// 按关键词搜索书籍。
class SearchBooksUseCase {
  final BookRepository _repository;

  const SearchBooksUseCase(this._repository);

  Future<BookPage> call(String query, {int page = 1}) =>
      _repository.searchBooks(query: query, page: page);
}
