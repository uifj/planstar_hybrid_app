import '../model/book_detail.dart';
import '../repository/book_repository.dart';

/// 获取书详情与目录。
class GetBookDetailUseCase {
  final BookRepository _repository;

  const GetBookDetailUseCase(this._repository);

  Future<BookDetail> call(int bookId) =>
      _repository.fetchBookDetail(bookId: bookId);
}
