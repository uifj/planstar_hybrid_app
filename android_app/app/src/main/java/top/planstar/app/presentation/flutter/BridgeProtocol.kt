package top.planstar.app.presentation.flutter

/**
 * Flutter 桥接协议常量（与 iOS `BaseFlutterContainer.swift` 内的 `BridgeProtocol` 保持一致）。
 *
 * 所有通道名、方法名、登录态载荷与错误码只在此处定义，业务代码不得再出现裸字符串，
 * 避免两端命名漂移导致消息静默丢失。
 */
object BridgeProtocol {

    /** 桥接日志统一 TAG */
    const val TAG = "PlanstarBridge"

    /** Flutter → 原生 方法通道（与原项目同名，不可修改） */
    const val CHANNEL_METHOD_CALL = "com.yw.flutter.method_call"

    /** 原生 → Flutter 通知通道（与原项目同名，不可修改） */
    const val CHANNEL_NOTIFY = "com.yw.flutter.notify"

    /** 原生 → Flutter 事件通道（登录态等状态变更广播，与 iOS 保持一致） */
    const val CHANNEL_EVENT = "com.yw.flutter.event"

    /** Dart 侧启动完成握手 */
    const val METHOD_FLUTTER_READY = "flutterReady"
    const val METHOD_GET_USER_INFO = "getUserInfo"
    const val METHOD_GET_BASE_URL = "getBaseUrl"
    const val METHOD_LOGOUT = "logout"
    const val METHOD_OPEN_LOGIN = "openLogin"
    const val METHOD_OPEN_READER = "openReader"

    /** 登录态通知方法名：载荷 [LOGIN_STATUS_YES] 已登录 / [LOGIN_STATUS_NO] 未登录 */
    const val METHOD_USER_LOGIN_STATUS = "userLoginStatus"

    const val LOGIN_STATUS_YES = "1"
    const val LOGIN_STATUS_NO = "2"

    /** Flutter 尚未握手完成（未收到 flutterReady） */
    const val CODE_NOT_READY = "NOT_READY"

    /** 未知 / 未支持的方法 */
    const val CODE_UNSUPPORTED = "UNSUPPORTED"

    /** 调用超时 */
    const val CODE_TIMEOUT = "TIMEOUT"

    /** 原生侧内部异常 */
    const val CODE_INTERNAL = "INTERNAL"
}
