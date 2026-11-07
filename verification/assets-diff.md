# V2 资源比对报告

- 原包清单：`verification\evidence\flutter_assets`（AssetManifest 1013 条）
- demo 清单：`flutter_module\pubspec.yaml`

## 1. 字体族

| 字体族 | 原包 | demo | 结论 |
| --- | --- | --- | --- |
| `MaterialIcons` | MaterialIcons-Regular.otf | — | ℹ️ `uses-material-design: true` 自动带入 |
| `MyFlutterApp` | MyFlutterApp.ttf | MyFlutterApp.ttf | ✅ 已复刻 |
| `YuewenFont` | YuewenFont_Regular.ttf | YuewenFont_Regular.ttf | ✅ 已复刻 |
| `YuewenPixel` | YuewenPixel_Regular.ttf | YuewenPixel-Regular.ttf | ✅ 已复刻 |
| `packages/cupertino_icons/CupertinoIcons` | CupertinoIcons.ttf | — | ℹ️ `cupertino_icons` 依赖自动带入 |

## 2. 字体文件内容（sha256 前 16 位）

| 文件 | 原包 | demo | 一致 |
| --- | --- | --- | --- |
| YuewenFont | 1d425de58aa32a6f | 1d425de58aa32a6f | ✅ |
| YuewenPixel | caf759065f529a68 | caf759065f529a68 | ✅ |
| MyFlutterApp | 2cd7397bee3d8802 | 2cd7397bee3d8802 | ✅ |

## 3. 资源清单分组

| 前缀 | 条目数 | 处理 |
| --- | --- | --- |
| `packages/flutter_tardis` | 1009 | 排除：flutter_tardis（PAG 动画/表情，第三方） |
| `assets/fonts` | 3 | 已复刻（字体） |
| `packages/cupertino_icons` | 1 | 排除：cupertino_icons（demo 通过依赖自动带入） |

## 4. 结论

- 字体族：`YuewenFont` / `YuewenPixel` / `MyFlutterApp` 三个原项目字体族均已声明并导入，
  文件内容以 sha256 判定同源（命名差异不影响加载）。
- 字体文件：交集的三个字体文件 sha256 完全一致（`YuewenPixel` 仅文件名分隔符不同）。
- 资源清单：`assets/` 下的业务图片/数据属于原项目内容资源，demo 不复制（页面结构复刻，内容使用 mock），
  属于可接受差异；`packages/flutter_tardis` 为第三方 PAG 资源，按约定排除。
