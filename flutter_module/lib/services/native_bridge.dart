import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Flutter 与原生桥接。
///
/// 通道命名与原项目一致：
/// - Flutter → 原生：`com.yw.flutter.method_call`
/// - 原生 → Flutter：`com.yw.flutter.notify`（登录态方法 `userLoginStatus`）
///
/// 边界与可靠性约定（混合开发最容易踩的两个坑）：
/// 1. 原生主动推送必须等 Dart 侧就绪 —— [notifyReady] 负责握手，原生对未就绪的引擎
///    会先入队，就绪后补发，避免消息静默丢失；
/// 2. 所有调用都有超时与异常兜底，避免某个原生异常把调用方 Future 永久挂起，
///    导致页面一直停在 loading 态。
class NativeBridge {
  /// 方法调用通道（与原项目 BaseFlutterActivity 注册的通道同名）
  static const MethodChannel _channel = MethodChannel(
    'com.yw.flutter.method_call',
  );

  /// 原生 → Flutter 通知通道（与原项目同名）
  static const MethodChannel _notifyChannel = MethodChannel(
    'com.yw.flutter.notify',
  );

  /// 登录态通知方法名（原项目约定："1" 已登录 / "2" 未登录）
  static const String _methodUserLoginStatus = 'userLoginStatus';

  /// 桥接调用超时时间：原生侧都是轻量读取，超过该时长按失败处理。
  static const Duration _callTimeout = Duration(seconds: 2);

  static final StreamController<Map<String, dynamic>> _loginStateController =
      StreamController<Map<String, dynamic>>.broadcast();

  static bool _handlerInstalled = false;

  /// 登录态变更事件（原生 -> Flutter），登录成功/退出登录时由原生主动推送。
  static Stream<Map<String, dynamic>> get loginStateChanges =>
      _loginStateController.stream;

  /// Dart 隔离区启动完成，通知原生可以安全推送消息。
  ///
  /// 必须早于任何依赖"原生主动推送"的页面监听逻辑执行。
  static void notifyReady() {
    _ensureHandlerInstalled();
    _channel.invokeMethod<bool>('flutterReady').catchError((Object e) {
      debugPrint('flutterReady handshake failed: $e');
      return null;
    });
  }

  static void _ensureHandlerInstalled() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _notifyChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case _methodUserLoginStatus:
          _handleUserLoginStatus(call.arguments);
          return true;
        default:
          return null;
      }
    });
  }

  /// 原生只下发 "1" / "2"（与原项目一致）；已登录时再回查一次用户信息，
  /// 保证昵称、token 等展示数据与原生 MMKV 一致。
  static void _handleUserLoginStatus(Object? arguments) {
    final loggedIn = arguments == '1' ||
        arguments == 1 ||
        (arguments is Map && arguments['loggedIn'] == true);
    if (!loggedIn) {
      _loginStateController.add({'loggedIn': false});
      return;
    }
    unawaited(_emitLoggedInUser());
  }

  static Future<void> _emitLoggedInUser() async {
    final info = await getUserInfo();
    _loginStateController.add({...(info ?? const {}), 'loggedIn': true});
  }

  /// 获取登录用户信息（由原生侧从 MMKV 中读取）。
  static Future<Map<String, dynamic>?> getUserInfo() async {
    final result = await _invoke<Map<Object?, Object?>>('getUserInfo');
    return result == null ? null : _toStringKeyMap(result);
  }

  /// 获取原生侧配置的请求 BaseUrl。
  static Future<String?> getBaseUrl() => _invoke<String>('getBaseUrl');

  /// 退出登录（原生侧清空 MMKV 登录态）。
  static Future<void> logout() async {
    await _invoke<void>('logout');
  }

  /// 打开原生登录页。
  static Future<void> openLogin() async {
    await _invoke<void>('openLogin');
  }

  /// 打开原生阅读页（对应原项目章节阅读 Activity）。
  static Future<void> openReader({
    required int bookId,
    required String title,
    required String author,
  }) async {
    await _invoke<void>('openReader', {
      'bookId': bookId,
      'title': title,
      'author': author,
    });
  }

  /// 统一调用入口：超时 + 错误归一化，失败返回 null 而不是抛出，
  /// 避免桥接异常穿透到 UI 层造成未捕获异常。
  static Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    try {
      return await _channel
          .invokeMethod<T>(method, args)
          .timeout(_callTimeout);
    } on PlatformException catch (e) {
      debugPrint('NativeBridge.$method failed: ${e.code} ${e.message}');
      return null;
    } on TimeoutException {
      debugPrint('NativeBridge.$method timeout after ${_callTimeout.inSeconds}s');
      return null;
    } on MissingPluginException catch (e) {
      debugPrint('NativeBridge.$method missing plugin: ${e.message}');
      return null;
    }
  }

  static Map<String, dynamic> _toStringKeyMap(Map<Object?, Object?> raw) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
}
