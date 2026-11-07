/// 阅读器仓库接口：阅读页由原生实现，Dart 侧只负责发出跳转请求。
abstract class ReaderRepository {
  Future<void> openReader({
    required int bookId,
    required String title,
    required String author,
  });
}
