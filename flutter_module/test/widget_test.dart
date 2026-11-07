// 模块烟雾测试：验证 Flutter 模块入口可按路由渲染页面。

import 'package:flutter_test/flutter_test.dart';

import 'package:qidian_flutter/main.dart';

void main() {
  testWidgets('Module renders category page smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QidianFlutterApp(route: '/book_category'));
    await tester.pump();

    // 书城页应包含书名与搜索占位。
    expect(find.text('书城'), findsOneWidget);
    expect(find.text('元尊'), findsOneWidget);
  });
}
