import '../repository/reader_repository.dart';

/// 打开原生阅读页。
class OpenReaderUseCase {
  final ReaderRepository _repository;

  const OpenReaderUseCase(this._repository);

  Future<void> call({
    required int bookId,
    required String title,
    required String author,
  }) {
    return _repository.openReader(bookId: bookId, title: title, author: author);
  }
}
