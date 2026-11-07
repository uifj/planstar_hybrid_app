/// Dart 与原生之间的桥接协议常量。
///
/// 通道名、方法名与原生侧注册的完全一致，是跨端契约，任何改动都必须双端同步，
/// 因此集中在这里而不是散落在调用点。
abstract final class BridgeProtocol {
  /// Flutter → 原生：方法调用通道。
  static const String channelMethodCall = 'com.yw.flutter.method_call';

  /// 原生 → Flutter：通知通道。
  static const String channelNotify = 'com.yw.flutter.notify';

  /// 原生 → Flutter：事件广播通道（登录态、主题等状态变更）。
  static const String channelEvent = 'com.yw.flutter.event';

  static const String methodFlutterReady = 'flutterReady';
  static const String methodGetUserInfo = 'getUserInfo';
  static const String methodGetBaseUrl = 'getBaseUrl';
  static const String methodLogout = 'logout';
  static const String methodOpenLogin = 'openLogin';
  static const String methodOpenReader = 'openReader';
  static const String methodUserLoginStatus = 'userLoginStatus';

  /// 原生引擎尚未就绪：此阶段调用会被原生拒绝，调用方需要降级而不是报错。
  static const String errorNotReady = 'NOT_READY';

  /// 原生未实现该方法（版本不一致时常见）。
  static const String errorUnsupported = 'UNSUPPORTED';

  /// 桥接调用超时。
  static const String errorTimeout = 'TIMEOUT';

  /// 原生侧内部异常。
  static const String errorInternal = 'INTERNAL';

  /// 原生约定的登录态取值："1" 已登录 / "2" 未登录。
  static const String loginStatusYes = '1';
  static const String loginStatusNo = '2';

  static const String keyLoggedIn = 'loggedIn';
  static const String keyNickname = 'nickname';
  static const String keyToken = 'token';
  static const String keyUserId = 'userId';
  static const String keyBookId = 'bookId';
  static const String keyTitle = 'title';
  static const String keyAuthor = 'author';
}
