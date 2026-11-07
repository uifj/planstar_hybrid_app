# V1 接口契约比对报告

- 原包样本：`verification\evidence\libapp.so`
- 提取 ASCII 串：34869 条
- demo 来源：android_app\app\src\main\java\com\qidian\demo\presentation\flutter\BaseFlutterContainer.kt / flutter_module\lib\services\native_bridge.dart

## 1. 已知通道存在性（原包）

| 通道 | 原包是否存在 |
| --- | --- |
| `com.yw.flutter.method_call` | 是 |
| `com.yw.flutter.notify` | 是 |
| `com.yw.flutter.book_detail` | 是 |
| `com.yw.flutter_tardis.multi_engin_broadcast_channel` | 是 |

## 2. 原包中出现的 `com.yw*` 字符串

- `com.yw.flutter.book_detail`
- `com.yw.flutter.channel_qr_login_in`
- `com.yw.flutter.channel_short_video`
- `com.yw.flutter.cloud_config`
- `com.yw.flutter.harmony.method_call`
- `com.yw.flutter.input_dialog`
- `com.yw.flutter.method_call`
- `com.yw.flutter.newuser.discountguide`
- `com.yw.flutter.notify`
- `com.yw.flutter.notify.book_store`
- `com.yw.flutter.notify.extraUnlock`
- `com.yw.flutter.notify.hongbao`
- `com.yw.flutter.notify.manga`
- `com.yw.flutter.notify.readroledanmaku`
- `com.yw.flutter.notify.subscribe`
- `com.yw.flutter.notify.welfare`
- `com.yw.flutter.notify_audio`
- `com.yw.flutter.notify_daily_read`
- `com.yw.flutter.notify_day_night`
- `com.yw.flutter.notify_floating`
- `com.yw.flutter.read_search`
- `com.yw.flutter.short_video_comment`
- `com.yw.flutter.single_coupon_channel`
- `com.yw.flutter_tardis.multi_container_sync_channel`
- `com.yw.flutter_tardis.multi_engin_broadcast_channel`

## 3. 路由探针（原包）

| 路由 | 是否存在 |
| --- | --- |
| `/book_category` | 否 |
| `/book_detail` | 是 |
| `/mine` | 否 |
| `/bookStore` | 否 |
| `/search` | 是 |
| `/bookshelf` | 是 |

## 4. demo 声明 vs 原包字符串

| 类型 | 名称 | 原包证据 | 结论 |
| --- | --- | --- | --- |
| 通道 | `com.yw.flutter.method_call` | 原包含该串 | ✅ PASS |
| 通道 | `com.yw.flutter.notify` | 原包含该串 | ✅ PASS |
| 方法 | `getBaseUrl` | 原包未找到（可能是 demo 自增方法） | ⚠️ WARN |
| 方法 | `getUserInfo` | 原包含该串 | ✅ PASS |
| 方法 | `logout` | 原包未找到（可能是 demo 自增方法） | ⚠️ WARN |
| 方法 | `openLogin` | 原包未找到（可能是 demo 自增方法） | ⚠️ WARN |
| 方法 | `openReader` | 原包含该串 | ✅ PASS |
| 方法 | `userLoginStatus` | 原包含该串 | ✅ PASS |
| 路由 | `/book_category` | 原包未找到 | ⚠️ WARN |
| 路由 | `/book_detail` | 原包含该串 | ✅ PASS |
| 路由 | `/mine` | 原包未找到 | ⚠️ WARN |

## 5. 汇总

- PASS 6 / WARN 5 / FAIL 0

> 说明：方法名 WARN 只代表该名未在 AOT 字符串池中以独立串出现（可能被内联或拼接），
> 需要 V4 交互回归做运行时确认；通道名 FAIL 属于阻塞级，必须修复。
