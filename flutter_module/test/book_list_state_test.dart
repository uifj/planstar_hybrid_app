import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:planstar_flutter/domain/model/book.dart';
import 'package:planstar_flutter/domain/model/book_page.dart';
import 'package:planstar_flutter/presentation/state/book_list_state.dart';

/// 测试用最小书籍对象。
Book _book(int id) => Book(
  bookId: id,
  bookName: '测试书$id',
  authorName: '作者$id',
  categoryName: '文学',
  description: '简介',
  chapterCount: 10,
  wordsCount: 100000,
  bookStatus: '1',
  bookStar: 90,
);

void main() {
  group('BookListState', () {
    test('首屏加载成功写入列表与分页信息', () async {
      final state = BookListState();
      addTearDown(state.dispose);
      state.updateLoader(
        (page) async =>
            BookPage(items: [_book(1), _book(2)], page: page, hasMore: true),
      );

      await state.loadFirstPage();

      expect(state.items.length, 2);
      expect(state.page, 1);
      expect(state.hasMore, isTrue);
      expect(state.hasLoaded, isTrue);
      expect(state.loading, isFalse);
      expect(state.error, isNull);
    });

    test('重复触底只发起一次翻页请求，成功后追加数据', () async {
      final gate = Completer<BookPage>();
      var calls = 0;
      final state = BookListState();
      addTearDown(state.dispose);
      state.updateLoader((page) {
        calls++;
        if (page == 1) {
          return Future.value(
            BookPage(items: [_book(1)], page: 1, hasMore: true),
          );
        }
        return gate.future;
      });

      await state.loadFirstPage();
      final firstLoadMore = state.loadMore();
      final secondLoadMore = state.loadMore();

      // 第二次触底在 loadingMore 为 true 时被直接拦截
      expect(calls, 2);

      gate.complete(BookPage(items: [_book(2)], page: 2, hasMore: false));
      await Future.wait([firstLoadMore, secondLoadMore]);

      expect(state.items.map((book) => book.bookId), [1, 2]);
      expect(state.page, 2);
      expect(state.hasMore, isFalse);
      expect(state.loadingMore, isFalse);
    });

    test('翻页成功后页码递增并追加数据', () async {
      final state = BookListState();
      addTearDown(state.dispose);
      state.updateLoader(
        (page) async =>
            BookPage(items: [_book(page)], page: page, hasMore: page < 3),
      );

      await state.loadFirstPage();
      expect(state.page, 1);

      await state.loadMore();
      await state.loadMore();

      expect(state.page, 3);
      expect(state.items.map((book) => book.bookId), [1, 2, 3]);
      expect(state.hasMore, isFalse);
    });

    test('刷新回到第 1 页并替换已有列表', () async {
      final state = BookListState();
      addTearDown(state.dispose);
      state.updateLoader(
        (page) async => BookPage(
          items: [_book(page == 1 ? 9 : page)],
          page: page,
          hasMore: true,
        ),
      );

      await state.loadFirstPage();
      await state.loadMore();
      expect(state.page, 2);
      expect(state.items.length, 2);

      await state.refresh();

      expect(state.page, 1);
      expect(state.items.map((book) => book.bookId), [9]);
    });

    test('翻页失败保留已有数据，只在底部给出错误提示', () async {
      final state = BookListState();
      addTearDown(state.dispose);
      state.updateLoader((page) async {
        if (page == 1) {
          return BookPage(items: [_book(1)], page: 1, hasMore: true);
        }
        throw Exception('network down');
      });

      await state.loadFirstPage();
      await state.loadMore();

      expect(state.items.length, 1);
      expect(state.error, isNull);
      expect(state.loadMoreError, isNotNull);
      expect(state.loadingMore, isFalse);
    });

    test('首屏失败进入整页错误态', () async {
      final state = BookListState();
      addTearDown(state.dispose);
      state.updateLoader((page) async => throw Exception('network down'));

      await state.loadFirstPage();

      expect(state.items, isEmpty);
      expect(state.error, isNotNull);
      expect(state.loading, isFalse);
    });

    test('旧请求的慢响应不会覆盖新关键词结果', () async {
      final slowResponse = Completer<BookPage>();
      final state = BookListState();
      addTearDown(state.dispose);
      state.updateLoader((page) => slowResponse.future);

      final oldRequest = state.loadFirstPage();
      state.updateLoader(
        (page) async => BookPage(items: [_book(2)], page: 1, hasMore: false),
      );
      await state.loadFirstPage();

      slowResponse.complete(
        BookPage(items: [_book(1)], page: 1, hasMore: true),
      );
      await oldRequest;

      expect(state.items.single.bookId, 2);
      expect(state.hasMore, isFalse);
    });
  });
}
