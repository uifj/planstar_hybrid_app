# Flutter 页面复刻验证报告（第 1 轮）

- 执行时间：2026-11-07
- 设备：华为 1080×2244 / density 480 / Android 11，字体缩放 1.0，zh-CN
- 原包：`CD3EDA2A9E624CA7E41FB5045F0B653E.apk`（com.qidian.QDReader 7.9.482）
- 候选：`android_app`（com.qidian.demo，debug）
- 脚本：`verification/scripts/v1_contract_diff.py`、`v2_asset_diff.py`、`v3_capture.ps1`

## 0. 结论摘要

| 层级 | 结论 | 说明 |
| --- | --- | --- |
| V1 接口契约 | ✅ PASS（0 FAIL） | 4 个已知通道全部在原包 `libapp.so` 字符串池中得到证实；demo 通道名 100% 对齐 |
| V2 资源 | ✅ 已补齐 | 3 个字体族全部导入，字体文件 sha256 完全一致；第三方 `flutter_tardis` 按约定排除 |
| V3 视觉基线 | ⚠️ 部分完成 | demo 7 个页面状态已采集；原包受登录墙限制，仅采到「隐私协议」「登录/引导」两态 |
| 执行中发现缺陷 | 已修复 | 书架页协程回包访问已销毁 binding 导致偶发 NPE（V3 执行时真实复现） |

## 1. V1 接口契约

证据来源：`lib/arm64-v8a/libapp.so` 的 ASCII 字符串池（共 34,869 条）。

原包中真实存在的通道（26 个 `com.yw*` 串）：

```
com.yw.flutter.method_call          ← 主方法通道，demo 已对齐
com.yw.flutter.notify               ← 通知通道，demo 已对齐
com.yw.flutter.book_detail
com.yw.flutter.read_search
com.yw.flutter.cloud_config
com.yw.flutter.input_dialog
com.yw.flutter.channel_qr_login_in
com.yw.flutter.channel_short_video
com.yw.flutter.harmony.method_call
com.yw.flutter.newuser.discountguide
com.yw.flutter.notify.book_store / .extraUnlock / .hongbao / .manga
com.yw.flutter.notify.readroledanmaku / .subscribe / .welfare
com.yw.flutter.notify_audio / notify_daily_read / notify_day_night / notify_floating
com.yw.flutter.short_video_comment
com.yw.flutter.single_coupon_channel
com.yw.flutter_tardis.multi_engin_broadcast_channel
com.yw.flutter_tardis.multi_container_sync_channel
```

方法级比对：

| 方法 | 原包 | 结论 |
| --- | --- | --- |
| `userLoginStatus` | 存在 | ✅ 对齐（载荷 "1"/"2" 未变） |
| `getUserInfo` | 存在 | ✅ 对齐 |
| `openReader` | 存在 | ✅ 对齐 |
| `getBaseUrl` / `logout` / `openLogin` | 未见独立串 | ⚠️ demo 自建方法，原包对应能力走云配置/登录页跳转，属可接受差异 |
| `flutterReady` | 不存在（原包为 `flutterDidLoad`） | ⚠️ demo 内部握手自命名，不影响跨端兼容，建议后续改名为 `flutterDidLoad` 以便与原包日志对照 |

路由名（原包裸串）：`bookDetail`、`mine`、`search`、`/book_detail`、`/search`、`/bookshelf` 存在；
`/book_category`、`/mine` 不存在 —— demo 这两个路由为自建命名，页面归属正确但路径不同。

## 2. V2 资源

| 字体族 | 原包 | demo | 结果 |
| --- | --- | --- | --- |
| `YuewenFont` | 27.8KB | 同文件 | sha256 `1d425de5…` 一致 |
| `YuewenPixel` | 17.9KB | 同文件（仅 `_` → `-` 命名差异） | sha256 `caf75906…` 一致 |
| `MyFlutterApp` | 3.4KB | **本轮导入** | sha256 `2cd7397b…` 一致 |

- `MaterialIcons` 由 `uses-material-design: true` 自动带入，`CupertinoIcons` 由依赖带入，均非缺失。
- AssetManifest 共 1,013 条，其中 1,009 条为 `packages/flutter_tardis`（第三方 PAG 资源，按约定排除），
  3 条为字体；原项目业务图片未复制（内容资源，demo 用 mock 替代）。

## 3. V3 视觉基线

已采集（`verification/candidate/`）：

| 页面 | demo | 原包 |
| --- | --- | --- |
| 启动/隐私协议 | — | `original/privacy_dialog.png` |
| 登录 | `demo/login.png` | `original/login.png`（微信/QQ/手机号登录） |
| 书架 | `demo/bookshelf_default.png` | 阻塞：需登录 |
| 书城 | `demo/bookcity.png` | 阻塞：需登录 |
| 搜索 | `demo/search.png` | 阻塞：需登录 |
| 听书 | `demo/listening.png` | 阻塞：需登录 |
| 我的 | `demo/mine.png` | 阻塞：需登录 |
| 阅读 | `demo/reader.png`、`demo/reader_toolbar.png` | 阻塞：需登录 |

原包登录墙说明：启动 → 隐私协议（`SplashActivity`）→ `GuidanceActivity`（微信/QQ/手机号），
无可用账号，因此书城/书架/详情类页面无法取得运行时基线。这部分继续沿用
「反编译资源 + ASCII 契约 + 人工核对」的证据路径，不纳入自动截图比对。

## 4. 本轮修复

1. **书架页偶发 NPE（P0，会导致闪退）**
   `BookshelfFragment.load()` 原用 `lifecycleScope`（Fragment 级），视图销毁后回包仍访问 `binding`。
   已改为 `viewLifecycleOwner.lifecycleScope` 并增加 `_binding ?: return@launch` 兜底。
   该问题在 V3 采集时真实复现（`NullPointerException at BookshelfFragment.getBinding`），非推测。
2. **补齐图标字体** `MyFlutterApp.ttf` + `pubspec.yaml` 声明，消除 V2 唯一红色差异。

## 5. 遗留项

| 级别 | 事项 |
| --- | --- |
| P1 | 原包登录墙后的 4 个 P0 页面无运行时基线；若需视觉打分，需要可用测试账号 |
| P1 | 搜索页仅有默认态，缺「输入中 / 有结果 / 空结果」三态 |
| P2 | demo 路由命名与原包裸串（`bookDetail` / `mine` / `search`）不一致 |
| P2 | 握手方法名 `flutterReady` 与原包 `flutterDidLoad` 不一致（仅内部语义） |
| P2 | 未执行 V4 交互序列逐帧录制与 V5 五态回归 |

## 6. 复跑方式

```powershell
python verification\scripts\v1_contract_diff.py
python verification\scripts\v2_asset_diff.py
powershell -ExecutionPolicy Bypass -File verification\scripts\v3_capture.ps1 -Target demo
powershell -ExecutionPolicy Bypass -File verification\scripts\v3_capture.ps1 -Target demo -FreshLogin   # 需重新登录
powershell -ExecutionPolicy Bypass -File verification\scripts\v3_capture.ps1 -Target original          # 需已安装原包
```
