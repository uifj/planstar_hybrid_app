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
│   ├── lib/                  # main.dart、pages/、services/native_bridge.dart
│   ├── assets/fonts/         # 与设计稿一致的三套字体
│   └── pubspec.yaml          # name: planstar_flutter + module 标识
├── ios_app/                  # iOS 原生宿主（Swift + UIKit）
│   ├── PlanstarHybrid/       # App / Core / Domain / Data / DI / Presentation
│   ├── Configs/              # Debug / Release / Profile 三套 xcconfig
│   ├── PlanstarHybrid.xcodeproj
│   └── Podfile               # install_all_flutter_pods('../flutter_module')
└── README.md / LICENSE
```

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

| 方向 | 通道 | 方法 / 载荷 |
|---|---|---|
| Flutter → 原生 | `com.yw.flutter.method_call` | `flutterReady`（握手）、`getUserInfo`、`getBaseUrl`、`logout`、`openLogin`、`openReader(bookId,title,author)` |
| 原生 → Flutter | `com.yw.flutter.notify` | `userLoginStatus`，载荷 `"1"` 已登录 / `"2"` 未登录 |

两端宿主的行为保持一致：

1. **引擎复用**：Android 侧按 route 缓存 `FlutterEngine`；iOS 用 `FlutterEngineGroup` 共享 VM/snapshot，每条路由一个引擎并缓存。
2. **预热**：宿主首帧后 400ms 触发预热，iOS 第二个引擎再延迟 600ms，避免启动阶段长帧。
3. **时序安全**：Dart 启动完成后回调 `flutterReady`；未就绪时原生发起的推送先入队（每路由上限 8 条），握手后补发，避免消息丢失。

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
