import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/bridge_protocol.dart';

/// 桥接失败统一异常：上层只需要判断 code，不必分别处理
/// PlatformException / 超时 / 通道缺失三种异常类型。
class BridgeException implements Exception {
  final String code;
  final String? message;

  const BridgeException(this.code, [this.message]);

  @override
  String toString() => 'BridgeException($code, $message)';
}

/// Flutter 与原生桥接。
///
/// 可靠性约定：
/// 1. 原生主动推送必须等 Dart 侧就绪 —— [notifyReady] 负责握手，
///    未就绪期间原生会入队并在就绪后补发；
/// 2. 所有调用都有超时，避免某个原生异常让页面永久停在 loading 态。
class NativeBridge {
  static const MethodChannel _methodChannel = MethodChannel(
    BridgeProtocol.channelMethodCall,
  );
  static const MethodChannel _notifyChannel = MethodChannel(
    BridgeProtocol.channelNotify,
  );
  static const EventChannel _eventChannel = EventChannel(
    BridgeProtocol.channelEvent,
  );

  /// 事件通道订阅：必须持有引用，否则可能被 GC 回收导致收不到原生事件。
  static StreamSubscription<dynamic>? _eventSubscription;

  /// 原生侧都是轻量读取，超过 2 秒按失败处理。
  static const Duration _callTimeout = Duration(seconds: 2);

  /// 登录态：用 ValueNotifier 暴露，页面无需自己维护流订阅与首次请求的竞态。
  static final ValueNotifier<bool> loginState = ValueNotifier<bool>(false);

  static const Map<String, dynamic> _loggedOutInfo = {
    BridgeProtocol.keyLoggedIn: false,
  };

  static bool _handlersInstalled = false;

  /// Dart 侧启动完成，通知原生可以安全推送消息。
  static void notifyReady() {
    _ensureHandlersInstalled();
    unawaited(_handshake());
  }

  static Future<void> _handshake() async {
    try {
      await _methodChannel
          .invokeMethod<bool>(BridgeProtocol.methodFlutterReady)
          .timeout(_callTimeout);
    } catch (error) {
      // 未就绪/通道缺失时重试没有意义，记录后由各调用点降级
      debugPrint('flutterReady handshake failed: $error');
    }
  }

  static void _ensureHandlersInstalled() {
    if (_handlersInstalled) return;
    _handlersInstalled = true;
    // 原生推送双通道兼容：notify 走 MethodChannel，event 走 EventChannel 广播
    _notifyChannel.setMethodCallHandler(_handleNativeCall);
    _eventSubscription ??= _eventChannel.receiveBroadcastStream().listen(
      _handleEvent,
      onError: (Object error) {
        // 独立 flutter run 时没有原生宿主，事件通道缺失属于预期情况
        debugPrint('event channel unavailable: $error');
      },
      cancelOnError: false,
    );
  }

  static void _handleEvent(dynamic event) {
    loginState.value = _parseLoggedIn(event);
  }

  static Future<Object?> _handleNativeCall(MethodCall call) async {
    if (call.method == BridgeProtocol.methodUserLoginStatus) {
      loginState.value = _parseLoggedIn(call.arguments);
      return true;
    }
    return null;
  }

  /// 原生只下发 "1"/"2"，兼容个别版本下发的布尔或 map。
  static bool _parseLoggedIn(Object? arguments) {
    if (arguments == BridgeProtocol.loginStatusYes) return true;
    if (arguments == 1) return true;
    if (arguments is bool) return arguments;
    if (arguments is Map) {
      return arguments[BridgeProtocol.keyLoggedIn] == true;
    }
    return false;
  }

  /// 读取登录用户信息。
  ///
  /// 桥接不可用时返回游客态而不是抛异常：登录信息属于增强内容，
  /// 让它阻塞「我的」页渲染得不偿失。
  static Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final result = await _invoke<Map<Object?, Object?>>(
        BridgeProtocol.methodGetUserInfo,
      );
      if (result == null) return _loggedOutInfo;
      return _normalizeUserInfo(_toStringKeyMap(result));
    } on BridgeException catch (error) {
      debugPrint('getUserInfo degraded: ${error.code} ${error.message}');
      return _loggedOutInfo;
    }
  }

  /// 原生返回的 map 不一定带 loggedIn，用昵称/token 兜底判断。
  static Map<String, dynamic> _normalizeUserInfo(Map<String, dynamic> raw) {
    final Object? explicitFlag = raw[BridgeProtocol.keyLoggedIn];
    final Object? nickname = raw[BridgeProtocol.keyNickname];
    final Object? token = raw[BridgeProtocol.keyToken];
    final hasProfile =
        (nickname is String && nickname.isNotEmpty) ||
        (token is String && token.isNotEmpty);
    return {
      ...raw,
      BridgeProtocol.keyLoggedIn: explicitFlag is bool
          ? explicitFlag
          : hasProfile,
    };
  }

  static Future<String?> getBaseUrl() =>
      _invoke<String>(BridgeProtocol.methodGetBaseUrl);

  /// 退出登录（原生清空本地登录态并推送 loginState）。
  static Future<void> logout() async {
    await _invoke<void>(BridgeProtocol.methodLogout);
    loginState.value = false;
  }

  /// 打开原生登录页，登录结果由原生推回。
  static Future<void> openLogin() async {
    await _invoke<void>(BridgeProtocol.methodOpenLogin);
  }

  /// 打开原生阅读页。
  static Future<void> openReader({
    required int bookId,
    required String title,
    required String author,
  }) async {
    await _invoke<void>(BridgeProtocol.methodOpenReader, {
      BridgeProtocol.keyBookId: bookId,
      BridgeProtocol.keyTitle: title,
      BridgeProtocol.keyAuthor: author,
    });
  }

  /// 统一调用入口：超时 + 异常归一化，失败抛 [BridgeException]。
  static Future<T?> _invoke<T>(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      return await _methodChannel
          .invokeMethod<T>(method, arguments)
          .timeout(_callTimeout);
    } on PlatformException catch (error) {
      throw BridgeException(
        error.code.isEmpty ? BridgeProtocol.errorInternal : error.code,
        error.message,
      );
    } on MissingPluginException catch (error) {
      // 没有原生宿主（如 flutter run 独立调试）等价于原生未就绪
      throw BridgeException(BridgeProtocol.errorNotReady, error.message);
    } on TimeoutException {
      throw const BridgeException(BridgeProtocol.errorTimeout, '原生调用超时');
    }
  }

  static Map<String, dynamic> _toStringKeyMap(Map<Object?, Object?> raw) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
}
