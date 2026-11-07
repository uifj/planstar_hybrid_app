import 'package:flutter_test/flutter_test.dart';

import 'package:planstar_flutter/data/mapper/book_mapper.dart';
import 'package:planstar_flutter/data/remote/gutendex_dto.dart';

GutendexBookDto _dto({
  int id = 1,
  String title = 'Pride and Prejudice',
  String authorName = 'Jane Austen',
  int downloadCount = 100,
  Map<String, String> formats = const {},
}) {
  return GutendexBookDto(
    id: id,
    title: title,
    authorName: authorName,
    downloadCount: downloadCount,
    formats: formats,
  );
}

void main() {
  final mapper = BookMapper();

  group('BookMapper.toBook', () {
    test('标题为空时回退「未知书名」', () {
      final book = mapper.toBook(_dto(title: '   '));
      expect(book.bookName, '未知书名');
    });

    test('作者为空时回退「未知作者」', () {
      final book = mapper.toBook(_dto(authorName: ''));
      expect(book.authorName, '未知作者');
    });

    test('标题/作者去除首尾空白', () {
      final book = mapper.toBook(
        _dto(title: ' 三体 ', authorName: ' 刘慈欣 '),
      );
      expect(book.bookName, '三体');
      expect(book.authorName, '刘慈欣');
    });

    test('下载量按每 50 次换算 1 字，章节数向上取整', () {
      final book = mapper.toBook(_dto(downloadCount: 100));
      // 100 * 50 = 5000 字；5000 / 3000 向上取整 = 2 章
      expect(book.wordsCount, 5000);
      expect(book.chapterCount, 2);
    });

    test('下载量为 0 时按下限 1 换算，避免字数为 0', () {
      final book = mapper.toBook(_dto(downloadCount: 0));
      expect(book.wordsCount, 50);
      expect(book.chapterCount, 1);
    });

    test('formats 中的 image/jpeg 映射为 coverUrl', () {
      final book = mapper.toBook(
        _dto(formats: {'image/jpeg': 'https://example.com/cover.jpg'}),
      );
      expect(book.coverUrl, 'https://example.com/cover.jpg');
    });

    test('缺少 image/jpeg 或值为空时 coverUrl 为 null', () {
      expect(mapper.toBook(_dto()).coverUrl, isNull);
      expect(
        mapper.toBook(_dto(formats: {'image/jpeg': ''})).coverUrl,
        isNull,
      );
    });
  });

  group('GutendexResponseDto.hasMore', () {
    test('next 非空表示还有下一页', () {
      final dto = GutendexResponseDto.fromJson({
        'count': 32,
        'next': 'https://gutendex.com/books?page=2',
        'results': const [],
      });
      expect(dto.next, isNotNull);
      expect(dto.hasMore, isTrue);
    });

    test('next 为 null 表示已到最后一页', () {
      final dto = GutendexResponseDto.fromJson({
        'count': 32,
        'next': null,
        'results': const [],
      });
      expect(dto.next, isNull);
      expect(dto.hasMore, isFalse);
    });

    test('next 为空字符串按没有下一页处理', () {
      final dto = GutendexResponseDto.fromJson({
        'count': 32,
        'next': '',
        'results': const [],
      });
      expect(dto.next, isNull);
      expect(dto.hasMore, isFalse);
    });
  });
}
