import '../../domain/model/book_detail.dart';
import '../../domain/model/book_page.dart';
import '../../domain/repository/book_repository.dart';
import '../local/local_books.dart';
import '../mapper/book_mapper.dart';
import '../remote/gutendex_api.dart';
import '../remote/gutendex_dto.dart';

/// 网络优先、本地兜底的书籍仓库。
///
/// Gutendex 每页固定返回 32 条，而产品要求对外每页 20 条，因此在仓库层
/// 用无状态的窗口算法把 API 页切片成对外的 20 条分页。
/// 兜底只发生在第一页：翻页失败时若再插入本地书，会造成同一批书重复出现。
class BookRepositoryImpl implements BookRepository {
  /// 对外分页大小，产品要求每页 20 条。
  static const int _pageSize = 20;

  /// Gutendex 接口每页固定返回条数。
  /// 来源：https://gutendex.com/books?page=1 的 results 恒为 32 条。
  static const int _apiPageSize = 32;

  final GutendexApi _api;
  final LocalBooksDataSource _local;
  final BookMapper _mapper;

  BookRepositoryImpl({
    GutendexApi? api,
    LocalBooksDataSource? local,
    BookMapper? mapper,
  }) : _api = api ?? GutendexApi(),
       _local = local ?? LocalBooksDataSource(),
       _mapper = mapper ?? BookMapper();

  @override
  Future<BookPage> fetchBooks({int page = 1}) {
    return _fetchWindow(page: page, fallback: _local.firstPage);
  }

  @override
  Future<BookPage> searchBooks({required String query, int page = 1}) {
    final keyword = query.trim();
    if (keyword.isEmpty) {
      return Future.value(
        BookPage(items: const [], page: page, hasMore: false),
      );
    }
    return _fetchWindow(
      page: page,
      search: keyword,
      fallback: () => _local.search(keyword),
    );
  }

  /// 按对外页码计算窗口并跨 API 页拼接。
  ///
  /// 不缓存跨请求状态，保证重复请求同一页结果一致。
  Future<BookPage> _fetchWindow({
    required int page,
    String? search,
    required BookPage Function() fallback,
  }) async {
    final safePage = page < 1 ? 1 : page;
    final offset = (safePage - 1) * _pageSize;
    final apiPage = offset ~/ _apiPageSize + 1;
    final localOffset = offset % _apiPageSize;

    try {
      final first = await _api.fetchBooks(page: apiPage, search: search);
      final results = <GutendexBookDto>[...first.results];
      var lastHasMore = first.hasMore;

      // pageSize(20) < apiPageSize(32)，一个窗口最多跨 2 个 API 页
      if (localOffset + _pageSize > results.length && lastHasMore) {
        final next = await _api.fetchBooks(page: apiPage + 1, search: search);
        results.addAll(next.results);
        lastHasMore = next.hasMore;
      }

      final start = localOffset < results.length ? localOffset : results.length;
      final end = start + _pageSize < results.length
          ? start + _pageSize
          : results.length;
      final window = results.sublist(start, end);
      if (window.isEmpty) {
        // 空结果按不可用处理，否则用户会看到空白书城
        return safePage == 1 ? fallback() : _emptyPage(safePage);
      }

      return BookPage(
        items: window.map(_mapper.toBook).toList(),
        page: safePage,
        hasMore: localOffset + _pageSize < results.length || lastHasMore,
      );
    } catch (_) {
      // 第一页失败回退本地书单；后续页失败返回空页，避免重复插入本地书
      return safePage == 1 ? fallback() : _emptyPage(safePage);
    }
  }

  @override
  Future<BookDetail> fetchBookDetail({required int bookId}) async {
    final localBook = _local.findById(bookId);
    try {
      // 接口按标题搜索，用本地书名缩小范围；网络书没有本地记录时搜索第一页再按 id 匹配
      final response = await _api.fetchBooks(search: localBook?.bookName);
      final dto = _findById(response.results, bookId);
      if (dto != null) return _mapper.toDetail(dto);
    } catch (_) {
      // 网络异常继续走本地兜底
    }
    if (localBook != null) return _local.detailOf(localBook);
    throw StateError('未找到书籍：$bookId');
  }

  GutendexBookDto? _findById(List<GutendexBookDto> results, int bookId) {
    for (final dto in results) {
      if (dto.id == bookId) return dto;
    }
    return null;
  }

  BookPage _emptyPage(int page) =>
      BookPage(items: const [], page: page, hasMore: false);
}
