import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'mock/mock_books.dart';
import 'pages/book_category_page.dart';
import 'pages/book_detail_page.dart';
import 'pages/mine_page.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  // 与原生侧握手：引擎已就绪，原生可以开始主动推送（未就绪期间的消息会补发）
  NativeBridge.notifyReady();
  final route = ui.PlatformDispatcher.instance.defaultRouteName;
  runApp(PlanstarFlutterApp(route: route));
}

class PlanstarFlutterApp extends StatelessWidget {
  final String route;
  const PlanstarFlutterApp({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '企划星 planstar_app',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE5353E),
          primary: const Color(0xFFE5353E),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F9),
        fontFamily: 'YuewenFont',
      ),
      home: _resolveRoute(route),
    );
  }

  Widget _resolveRoute(String route) {
    switch (route) {
      case '/mine':
        return const MinePage();
      case '/book_detail':
        return const BookDetailPage(book: _placeholderBook);
      case '/book_category':
      default:
        return const BookCategoryPage();
    }
  }
}
