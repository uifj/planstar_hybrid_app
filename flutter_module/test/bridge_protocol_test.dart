// 桥接协议契约测试：通道名/方法名/错误码/载荷 key 是原生与 Dart 的硬约定，
// 任何一端改动都会导致断链。纯常量断言，不依赖原生通道，可直接 flutter test。

import 'package:flutter_test/flutter_test.dart';

import 'package:planstar_flutter/core/bridge_protocol.dart';

void main() {
  group('BridgeProtocol', () {
    test('三个通道名与原生侧一致', () {
      expect(BridgeProtocol.channelMethodCall, 'com.yw.flutter.method_call');
      expect(BridgeProtocol.channelNotify, 'com.yw.flutter.notify');
      expect(BridgeProtocol.channelEvent, 'com.yw.flutter.event');
    });

    test('7 个方法名与原生侧一致', () {
      expect(BridgeProtocol.methodFlutterReady, 'flutterReady');
      expect(BridgeProtocol.methodGetUserInfo, 'getUserInfo');
      expect(BridgeProtocol.methodGetBaseUrl, 'getBaseUrl');
      expect(BridgeProtocol.methodLogout, 'logout');
      expect(BridgeProtocol.methodOpenLogin, 'openLogin');
      expect(BridgeProtocol.methodOpenReader, 'openReader');
      expect(BridgeProtocol.methodUserLoginStatus, 'userLoginStatus');
    });

    test('4 个错误码与原生侧一致', () {
      expect(BridgeProtocol.errorNotReady, 'NOT_READY');
      expect(BridgeProtocol.errorUnsupported, 'UNSUPPORTED');
      expect(BridgeProtocol.errorTimeout, 'TIMEOUT');
      expect(BridgeProtocol.errorInternal, 'INTERNAL');
    });

    test('登录态取值为 "1" / "2"', () {
      expect(BridgeProtocol.loginStatusYes, '1');
      expect(BridgeProtocol.loginStatusNo, '2');
    });

    test('登录信息与跳转载荷 key 稳定', () {
      expect(BridgeProtocol.keyLoggedIn, 'loggedIn');
      expect(BridgeProtocol.keyNickname, 'nickname');
      expect(BridgeProtocol.keyToken, 'token');
      expect(BridgeProtocol.keyUserId, 'userId');
      expect(BridgeProtocol.keyBookId, 'bookId');
      expect(BridgeProtocol.keyTitle, 'title');
      expect(BridgeProtocol.keyAuthor, 'author');
    });
  });
}
