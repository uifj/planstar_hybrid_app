// 桥接协议契约测试：通道名/方法名是原生与 Dart 的硬约定，改动会直接导致断链。
// 不依赖原生通道，flutter test 可在纯 Dart 环境运行。

import 'package:flutter_test/flutter_test.dart';

import 'package:planstar_flutter/core/app_router.dart';
import 'package:planstar_flutter/core/bridge_protocol.dart';

void main() {
  group('BridgeProtocol', () {
    test('三个通道名与原生侧一致', () {
      expect(BridgeProtocol.channelMethodCall, 'com.yw.flutter.method_call');
      expect(BridgeProtocol.channelNotify, 'com.yw.flutter.notify');
      expect(BridgeProtocol.channelEvent, 'com.yw.flutter.event');
    });

    test('方法名与原生侧一致', () {
      expect(BridgeProtocol.methodFlutterReady, 'flutterReady');
      expect(BridgeProtocol.methodGetUserInfo, 'getUserInfo');
      expect(BridgeProtocol.methodGetBaseUrl, 'getBaseUrl');
      expect(BridgeProtocol.methodLogout, 'logout');
      expect(BridgeProtocol.methodOpenLogin, 'openLogin');
      expect(BridgeProtocol.methodOpenReader, 'openReader');
      expect(BridgeProtocol.methodUserLoginStatus, 'userLoginStatus');
    });

    test('错误码与登录态常量稳定', () {
      expect(BridgeProtocol.errorNotReady, 'NOT_READY');
      expect(BridgeProtocol.errorUnsupported, 'UNSUPPORTED');
      expect(BridgeProtocol.errorTimeout, 'TIMEOUT');
      expect(BridgeProtocol.errorInternal, 'INTERNAL');
      expect(BridgeProtocol.loginStatusYes, '1');
      expect(BridgeProtocol.loginStatusNo, '2');
    });
  });

  group('resolveInitialRoute', () {
    test('已知路由原样返回', () {
      expect(resolveInitialRoute(routeBookCategory), routeBookCategory);
      expect(resolveInitialRoute(routeMine), routeMine);
      expect(resolveInitialRoute(routeBookDetail), routeBookDetail);
    });

    test('未知或空路由回落书城', () {
      expect(resolveInitialRoute('/unknown'), routeBookCategory);
      expect(resolveInitialRoute(''), routeBookCategory);
    });
  });
}
