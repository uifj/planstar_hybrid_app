import '../model/book_page.dart';
import '../repository/book_repository.dart';

/// 获取书城列表。
class GetBooksUseCase {
  final BookRepository _repository;

  const GetBooksUseCase(this._repository);

  Future<BookPage> call({int page = 1}) => _repository.fetchBooks(page: page);
}
