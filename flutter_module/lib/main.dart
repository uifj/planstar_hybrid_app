import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'domain/model/book.dart';
import 'presentation/pages/book_category_page.dart';
import 'presentation/pages/book_detail_page.dart';
import 'presentation/pages/mine_page.dart';
import 'services/native_bridge.dart';

const _placeholderBook = Book(
  bookId: 1013391,
  bookName: '示例书籍',
  authorName: '企划星作者',
  categoryName: '玄幻',
  description: '这是一本示例书籍，用于演示书详情页面的混合开发容器跳转。',
  chapterCount: 12,
  wordsCount: 30000,
  bookStatus: '1',
  bookStar: 90,
);

/// Flutter 模块入口：由原生容器（FlutterFragment / FlutterActivity）通过
/// initialRoute 决定渲染哪个页面，对应原生自研 BaseFlutterActivity 的路由分发。
void main() {
  // 进程内启动起点：runApp 前打点，首帧回调里结算
  final startedAt = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  // 与原生侧握手：引擎已就绪，原生可以开始主动推送（未就绪期间的消息会补发）
  NativeBridge.notifyReady();
  final route = ui.PlatformDispatcher.instance.defaultRouteName;
  runApp(PlanstarFlutterApp(route: route));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final cost = DateTime.now().difference(startedAt).inMilliseconds;
    // debugPrint 在 release 下不输出，不影响线上行为
    debugPrint('[PlanstarBridge] first_frame cost=${cost}ms');
  });
}

class PlanstarFlutterApp extends StatelessWidget {
  final String route;
  const PlanstarFlutterApp({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '企划星 planstar_app',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _resolveHome(),
    );
  }

  Widget _resolveHome() {
    switch (resolveInitialRoute(route)) {
      case routeMine:
        return const MinePage();
      case routeBookDetail:
        return const BookDetailPage(book: _placeholderBook);
      case routeBookCategory:
      default:
        return const BookCategoryPage();
    }
  }
}
