import 'package:flutter_test/flutter_test.dart';
import 'package:planstar_flutter/data/local/local_books.dart';
import 'package:planstar_flutter/data/remote/gutendex_api.dart';
import 'package:planstar_flutter/data/remote/gutendex_dto.dart';
import 'package:planstar_flutter/data/repository/book_repository_impl.dart';

/// 假 Gutendex：按固定 32 条/页生成连续 id，用于验证仓库层的窗口切片。
class FakeGutendexApi extends GutendexApi {
  final int total;

  /// 需要抛异常的 API 页码（从 1 开始）。
  final Set<int> failPages;

  /// 实际请求过的 API 页码；search 关键词按请求顺序记录。
  final List<int> requestedPages = [];
  final List<String?> requestedSearch = [];

  FakeGutendexApi({this.total = 70, this.failPages = const {}});

  static const int apiPageSize = 32;

  @override
  Future<GutendexResponseDto> fetchBooks({int page = 1, String? search}) async {
    requestedPages.add(page);
    requestedSearch.add(search);
    if (failPages.contains(page)) {
      throw Exception('network down: page $page');
    }
    final start = (page - 1) * apiPageSize;
    final end = start + apiPageSize < total ? start + apiPageSize : total;
    final results = <GutendexBookDto>[
      for (var id = start + 1; id <= end; id++)
        GutendexBookDto(
          id: id,
          title: 'Book $id',
          authorName: 'Author $id',
          downloadCount: 100,
          formats: const {},
        ),
    ];
    final hasMore = end < total;
    return GutendexResponseDto(
      count: total,
      next: hasMore ? 'https://gutendex.com/books?page=${page + 1}' : null,
      results: results,
    );
  }
}

void main() {
  group('BookRepositoryImpl 对外分页（每页 20 条）', () {
    test('第 1 页返回 20 条、page=1、hasMore=true', () async {
      final api = FakeGutendexApi();
      final repo = BookRepositoryImpl(api: api, local: LocalBooksDataSource());

      final result = await repo.fetchBooks(page: 1);

      expect(result.items.length, 20);
      expect(
        result.items.map((b) => b.bookId),
        List.generate(20, (i) => i + 1),
      );
      expect(result.page, 1);
      expect(result.hasMore, isTrue);
      expect(api.requestedPages, [1]);
    });

    test('第 2 页跨 API 页边界返回 20 条，且与第 1 页无重复 id', () async {
      final api = FakeGutendexApi();
      final repo = BookRepositoryImpl(api: api, local: LocalBooksDataSource());

      final first = await repo.fetchBooks(page: 1);
      final second = await repo.fetchBooks(page: 2);

      expect(second.items.length, 20);
      expect(
        second.items.map((b) => b.bookId),
        List.generate(20, (i) => i + 21),
      );
      expect(second.hasMore, isTrue);
      // 第 2 页 offset=20，需要跨 API 第 1、2 页
      expect(api.requestedPages, [1, 1, 2]);
      final firstIds = first.items.map((b) => b.bookId).toSet();
      expect(second.items.where((b) => firstIds.contains(b.bookId)), isEmpty);
    });

    test('第 3 页返回 20 条，累计 60 条无重复', () async {
      final api = FakeGutendexApi();
      final repo = BookRepositoryImpl(api: api, local: LocalBooksDataSource());

      final pages = <int>[];
      for (var page = 1; page <= 3; page++) {
        final result = await repo.fetchBooks(page: page);
        expect(result.items.length, 20);
        pages.addAll(result.items.map((b) => b.bookId));
      }

      expect(pages.length, 60);
      expect(pages.toSet().length, 60);
      expect(pages, List.generate(60, (i) => i + 1));
    });

    test('末页不足 20 条时 hasMore=false', () async {
      final api = FakeGutendexApi();
      final repo = BookRepositoryImpl(api: api, local: LocalBooksDataSource());

      final result = await repo.fetchBooks(page: 4);

      // 共 70 条：第 4 页只剩 10 条
      expect(result.items.length, 10);
      expect(
        result.items.map((b) => b.bookId),
        List.generate(10, (i) => i + 61),
      );
      expect(result.hasMore, isFalse);
    });

    test('第 1 页网络异常时回退本地书单', () async {
      final repo = BookRepositoryImpl(
        api: FakeGutendexApi(failPages: const {1}),
        local: LocalBooksDataSource(),
      );

      final result = await repo.fetchBooks(page: 1);

      expect(result.items.length, LocalBooksDataSource.books.length);
      expect(result.page, 1);
      expect(result.hasMore, isFalse);
    });

    test('第 2 页网络异常时返回空页且不重复插入本地书', () async {
      // 第 2 页需要跨 API 页：第一次成功、第二次（API 第 2 页）失败
      final repo = BookRepositoryImpl(
        api: FakeGutendexApi(failPages: const {2}),
        local: LocalBooksDataSource(),
      );

      final result = await repo.fetchBooks(page: 2);

      expect(result.items, isEmpty);
      expect(result.page, 2);
      expect(result.hasMore, isFalse);
    });

    test('搜索使用相同的窗口算法并透传关键词', () async {
      final api = FakeGutendexApi();
      final repo = BookRepositoryImpl(api: api, local: LocalBooksDataSource());

      final result = await repo.searchBooks(query: 'flutter', page: 2);

      expect(result.items.length, 20);
      expect(
        result.items.map((b) => b.bookId),
        List.generate(20, (i) => i + 21),
      );
      expect(result.hasMore, isTrue);
      expect(api.requestedSearch, ['flutter', 'flutter']);
      expect(api.requestedPages, [1, 2]);
    });
  });
}
