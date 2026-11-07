# 企划星 planstar_app

一个 **原生 + Flutter 混合开发** 示例工程：Android（Kotlin / CleanDDD）与 iOS（Swift / UIKit）各自作为宿主，复用同一份 Flutter 模块提供「书城」「我的」页面；「书架」「听书」保持原生实现。

- 应用名称：企划星 planstar_app
- Android 包名 / iOS Bundle ID：`top.planstar.app`
- Flutter 模块标识：`planstar_flutter`（androidPackage / iosBundleIdentifier：`top.planstar.app.flutter`）

## 功能概览

| 模块 | 实现 | 说明 |
|---|---|---|
| 登录 | 原生 | 演示账号 `demo / 123456`；优先请求远程，失败时本地校验；登录态持久化 |
| 书架 | 原生 | 缓存优先渲染 + 网络刷新，失败回退本地书单 |
| 书城 | Flutter | 路由 `/book_category`，通过桥接调用原生能力 |
| 听书 | 原生 | 本地音频列表与播放状态展示 |
| 我的 | Flutter | 路由 `/mine`，登录态由原生主动推送 |
| 阅读页 | 原生 | 目录、字号、4 套主题（白/羊皮纸/护眼绿/夜间黑） |

## 目录结构

```
planstar_hybrid_app/
├── android_app/              # Android 原生宿主（Kotlin + CleanDDD）
│   ├── app/                  # 业务代码、资源、清单
│   ├── settings.gradle       # AAR 仓库指向 ../flutter_module/build/host/outputs/repo
│   └── gradlew(.bat)
├── flutter_module/           # Flutter 模块（Dart 代码 + AAR 产物）
│   ├── lib/                  # 按 core / domain / data / presentation 分层
│   │   ├── core/             # 路由表、主题、桥接协议等跨层基础设施
│   │   ├── domain/           # 领域模型、仓库接口、用例（纯 Dart，不依赖 UI 与 IO）
│   │   ├── data/             # DTO、Mapper、远程/本地数据源、仓库实现
│   │   ├── presentation/     # 页面、组件、分页状态机（ChangeNotifier）
│   │   ├── services/         # 原生桥接调用封装（NativeBridge）
│   │   └── main.dart         # 模块入口：解析 initialRoute + 首帧埋点
│   ├── test/                 # 桥接契约、分页状态机、DTO 映射单测
│   ├── assets/fonts/         # 与设计稿一致的三套字体
│   └── pubspec.yaml          # name: planstar_flutter + module 标识
├── ios_app/                  # iOS 原生宿主（Swift + UIKit）
│   ├── PlanstarHybrid/       # App / Core / Domain / Data / DI / Presentation
│   ├── Configs/              # Debug / Release / Profile 三套 xcconfig
│   ├── PlanstarHybrid.xcodeproj
│   └── Podfile               # install_all_flutter_pods('../flutter_module')
├── .github/workflows/ci.yml  # CI：静态检查、单测、AAR 与 APK 构建
└── README.md / LICENSE
```

各层职责与依赖方向：

| 层 | 职责 | 依赖方向 |
|---|---|---|
| `core` | 路由常量与归一化、主题、桥接协议常量（通道/方法/错误码） | 被所有层引用，不反向依赖 |
| `domain` | `Book` / `BookPage` 等领域模型、仓库接口、业务用例 | 只依赖 Dart 与 core，不感知 Flutter UI |
| `data` | Gutendex DTO 与解析、`BookMapper`、远程/本地数据源、仓库实现 | 实现 domain 接口，向上层屏蔽接口差异 |
| `presentation` | 页面、可复用组件、`BookListState` 分页状态机 | 只依赖 domain / core，不直接拼装 HTTP |
| `services` | `NativeBridge`：MethodChannel / EventChannel 调用与超时归一化 | 供 presentation 调用，协议常量来自 core |

> 本地验证产物（原 APK 快照、一致性报告等）位于隐藏目录 `.verification/`，已在 `.gitignore` 中忽略。

## 技术栈

**Android**
- Kotlin 2.2.20、AGP 8.11.1、Gradle 8.14、compileSdk/targetSdk 36、minSdk 24、JVM 17
- ViewBinding、Fragment、RecyclerView
- OkHttp 3.12.6 / Retrofit 2.9.0 / Gson 2.8.9（与原 APK 对齐）
- MMKV 1.3.9（本地键值存储）、Kotlin Coroutines 1.6.0

**Flutter**
- Flutter 3.41.9 / Dart SDK ^3.11.5
- 字体：`YuewenFont`、`YuewenPixel`、`MyFlutterApp`

**iOS**
- Swift 5、UIKit（纯代码布局）、SceneDelegate、iOS 15.0+
- `FlutterEngineGroup` + `FlutterViewController` 嵌入

## 环境要求

- Flutter SDK 3.41.x（`flutter --version` 可验证）
- Android SDK 36 + JDK 17
- iOS 构建需 macOS + Xcode + CocoaPods

## Android 构建与运行

```bash
# 1. 生成 Flutter AAR（首次或 Flutter 代码有变更时执行）
cd flutter_module
flutter pub get
flutter build aar

# 2. 编译宿主 App
cd ../android_app
./gradlew :app:assembleDebug      # Windows: .\gradlew.bat :app:assembleDebug
```

产物：`android_app/app/build/outputs/apk/debug/app-debug.apk`。
AAR 坐标：`top.planstar.app.flutter:flutter_debug:1.0` / `flutter_release:1.0`，仓库地址由 `settings.gradle` 以相对路径指向 `../flutter_module/build/host/outputs/repo`，整个根目录可直接搬迁。

## iOS 构建与运行

```bash
cd flutter_module
flutter pub get                    # 重新生成含 macOS 路径的 Generated.xcconfig
flutter build ios --config-only

cd ../ios_app
pod install
open PlanstarHybrid.xcworkspace    # 必须打开 .xcworkspace
```

在 Xcode 中选择签名 Team 与模拟器后运行。工程已设置 `ENABLE_USER_SCRIPT_SANDBOXING = NO`，以满足 Flutter 构建脚本阶段的要求。

## 原生 ↔ Flutter 桥接契约

| 方向 | 通道 | 方法 / 载荷 | 说明 |
|---|---|---|---|
| Flutter → 原生 | `com.yw.flutter.method_call` | `flutterReady`（握手）、`getUserInfo`、`getBaseUrl`、`logout`、`openLogin`、`openReader(bookId,title,author)` | 方法调用主通道 |
| 原生 → Flutter | `com.yw.flutter.notify` | `userLoginStatus`，载荷 `"1"` 已登录 / `"2"` 未登录 | 单点状态通知 |
| 原生 → Flutter | `com.yw.flutter.event` | `userLoginStatus`，载荷同上 | 事件通道广播，与 notify 双通道兼容 |

错误码与触发条件：

| 错误码 | 触发条件 | 调用方处理约定 |
|---|---|---|
| `NOT_READY` | 尚未收到 `flutterReady` 握手时调用受限方法（`getUserInfo`/`getBaseUrl`/`logout`/`openLogin`/`openReader`） | 降级为游客态或提示重试，不阻塞页面渲染 |
| `UNSUPPORTED` | 方法名未实现或两端版本不一致 | 记录日志并降级，不做无限重试 |
| `TIMEOUT` | 原生 2 秒内未响应 | 抛 `BridgeException(TIMEOUT)`，页面进入可重试错误态 |
| `INTERNAL` | 原生侧内部异常（`PlatformException` 无 code） | 抛 `BridgeException(INTERNAL)`，按失败处理 |

两端宿主的行为保持一致：

1. **未就绪返回错误而非静默成功**：引擎未完成握手时，原生对受限方法必须回 `NOT_READY`，不得返回 `null`/空数据，否则 Dart 侧会把「未就绪」误判成「无数据」。原生主动推送则走队列，等握手完成后再补发。
2. **引擎复用**：Android 侧按 route 缓存 `FlutterEngine`（`FlutterEngineGroup` 共享 VM/snapshot）；iOS 同理，每条路由一个引擎并缓存。
3. **时序安全**：Dart 启动完成后回调 `flutterReady`；未就绪期间原生发起的消息先入队（每路由上限 8 条），握手后 flush。

## 性能优化

- **引擎预热**：宿主首帧后延迟 400ms 创建书城引擎，再延迟 600ms 创建「我的」引擎，错峰避开启动阶段长帧。
- **按路由缓存引擎**：Android 使用 `FlutterEngineCache` + `FlutterFragment.withCachedEngine(route)`，iOS 使用 `engines[route]`，切 Tab 不重复创建引擎。
- **事件/消息队列上限 8**：每条路由的待发消息最多缓存 8 条，超出丢弃最旧一条，防止引擎长时间未就绪导致内存无界增长。
- **列表 cacheExtent 600**：书城列表预构建一屏外内容，滚动时减少空白；详情/搜索页按需使用 400。
- **图片 cacheWidth**：封面按 300px 宽度解码，降低大图带来的内存与解码开销。
- **页面保活**：Android Tab 使用 `add/show/hide` 而非 `replace`，iOS 复用 `UITabBarController` 子控制器，切换后保留滚动位置与已加载数据。
- **启动埋点**：Debug 下统一输出 `[PlanstarBridge] <event> route=... cost=...ms`，覆盖 `engine_create`、`tab_switch`、`first_frame` 三段耗时；Release 不输出。

## CI

`.github/workflows/ci.yml` 在 push / pull_request 到 `main` 时触发，`ubuntu-latest` 上依次执行四项检查（超时 20 分钟）：

```bash
# 工作目录 flutter_module
flutter pub get
flutter analyze --no-pub     # 1. 静态检查
flutter test                 # 2. 单元测试
flutter build aar            # 3. 构建 Flutter AAR

# 工作目录仓库根
chmod +x android_app/gradlew
./android_app/gradlew -p android_app :app:assembleDebug --no-daemon   # 4. 编译 Android Debug APK
```

构建成功后上传 `app-debug.apk` 产物，保留 7 天。

## 数据源

- 书单：Gutendex 公版书 API `https://gutendex.com/books`，失败时回退内置 9 本书单
- 登录：`https://httpbin.org/` 回显校验，离线时使用演示账号本地校验
- 演示账号：`demo` / `123456`

## 应用标识

| 项 | 值 |
|---|---|
| 应用显示名 | 企划星 planstar_app |
| Android applicationId / namespace | `top.planstar.app` |
| iOS Bundle ID | `top.planstar.app` |
| Flutter 模块包名 | `planstar_flutter` |
| 启动图标 | 自适应图标（`mipmap-anydpi-v26` + 5 档密度，含圆形图标） |

## License

本项目基于 [MIT License](LICENSE) 开源。
