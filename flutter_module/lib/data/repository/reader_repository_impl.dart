import 'package:flutter/foundation.dart';

import '../../domain/repository/reader_repository.dart';
import '../../services/native_bridge.dart';

/// 阅读器仓库实现：把领域层的「打开阅读」翻译成桥接调用。
class NativeReaderRepository implements ReaderRepository {
  @override
  Future<void> openReader({
    required int bookId,
    required String title,
    required String author,
  }) async {
    try {
      await NativeBridge.openReader(
        bookId: bookId,
        title: title,
        author: author,
      );
    } on BridgeException catch (error) {
      // 原生不可用时跳转失败，但详情页需要给用户明确提示，
      // 因此记录原因后继续向上抛出，由页面转成 SnackBar。
      debugPrint('openReader failed: ${error.code} ${error.message}');
      rethrow;
    }
  }
}
