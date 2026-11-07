import '../data/local/local_books.dart';
import '../data/repository/book_repository_impl.dart';
import '../data/repository/reader_repository_impl.dart';
import '../domain/repository/book_repository.dart';
import '../domain/repository/reader_repository.dart';
import '../domain/usecase/get_book_detail_usecase.dart';
import '../domain/usecase/get_books_usecase.dart';
import '../domain/usecase/open_reader_usecase.dart';
import '../domain/usecase/search_books_usecase.dart';

/// 极简依赖注入：模块只有一层页面，引入 provider/riverpod 收益不足以抵消成本，
/// 这里只做唯一实例与 UseCase 的组装。
abstract final class ServiceLocator {
  static final BookRepository bookRepository = BookRepositoryImpl();
  static final ReaderRepository readerRepository = NativeReaderRepository();

  static final GetBooksUseCase getBooks = GetBooksUseCase(bookRepository);
  static final SearchBooksUseCase searchBooks = SearchBooksUseCase(
    bookRepository,
  );
  static final GetBookDetailUseCase getBookDetail = GetBookDetailUseCase(
    bookRepository,
  );
  static final OpenReaderUseCase openReader = OpenReaderUseCase(
    readerRepository,
  );

  /// 分类属于本地书单的展示分类，由数据层统一维护。
  static List<String> get bookCategories => LocalBooksDataSource.categories;
}
