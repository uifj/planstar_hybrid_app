# V3 基线截图采集
#
# 用途：在同一台设备（1080x2244 / density 480）、同一字体缩放与语言环境下，
#       按固定操作序列采集页面状态截图，供 V3 视觉比对与 V5 状态回归使用。
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File verification\scripts\v3_capture.ps1 -Target demo
#   powershell -ExecutionPolicy Bypass -File verification\scripts\v3_capture.ps1 -Target original
#   powershell -ExecutionPolicy Bypass -File verification\scripts\v3_capture.ps1 -Target demo -FreshLogin
#
# 约定：
#   - 截图统一走 /sdcard 中转 + adb pull，避免 PowerShell 重定向破坏 PNG 二进制；
#   - 每个状态之间固定等待，规避动画中间帧；
#   - demo 只导出 LoginActivity（LAUNCHER），MainActivity/ReaderActivity 未导出，
#     因此入口统一走 LoginActivity，阅读页靠点击书架首本书进入。

param(
    [ValidateSet('demo', 'original')]
    [string]$Target = 'demo',
    [switch]$FreshLogin
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$OutDir = Join-Path $Root "verification\candidate\$Target"
New-Item -ItemType Directory -Force $OutDir | Out-Null

$DemoPkg = 'com.qidian.demo'
$OrigPkg = 'com.qidian.QDReader'

function Shot([string]$Name) {
    adb shell screencap -p /sdcard/_v3.png | Out-Null
    adb pull /sdcard/_v3.png (Join-Path $OutDir "$Name.png") | Out-Null
    Write-Host "  [shot] $Name"
}

function Tap([int]$X, [int]$Y, [int]$WaitMs = 1200) {
    adb shell input tap $X $Y | Out-Null
    Start-Sleep -Milliseconds $WaitMs
}

function Start-App([string]$Pkg, [string]$Activity, [int]$WaitMs = 3000) {
    adb shell am start -n "$Pkg/$Activity" | Out-Null
    Start-Sleep -Milliseconds $WaitMs
}

# 底部四个 Tab 的中心坐标（1080 宽均分四等份，y 取图标行；2120 会落到图标上方的空隙）
$TabY = 2154
$TabShelf = 146
$TabStore = 417
$TabListen = 689
$TabMine = 958

if ($Target -eq 'demo') {
    if ($FreshLogin) {
        Write-Host '清除 demo 数据，采集登录页基线 ...'
        adb shell pm clear $DemoPkg | Out-Null
    }
    adb shell am force-stop $DemoPkg | Out-Null
    # 安装完成后系统安装器可能残留“安装成功”弹窗，先回桌面再启动，避免遮挡截图
    adb shell input keyevent KEYCODE_HOME | Out-Null
    Start-Sleep -Milliseconds 800

    # 1. 启动（已登录时直接进入书架；网络不可达时需等 OkHttp 超时后回退本地书单）
    Start-App $DemoPkg '.presentation.login.LoginActivity' 30000
    Shot 'bookshelf_default'

    # 2. 书城（Flutter 容器）
    Tap $TabStore $TabY 5000
    Shot 'bookcity'

    # 3. 听书
    Tap $TabListen $TabY 2000
    Shot 'listening'

    # 4. 我的（Flutter 容器）
    Tap $TabMine $TabY 5000
    Shot 'mine'

    # 5. 原生阅读页：点击书架第一本书进入
    Tap $TabShelf $TabY 1500
    Tap 208 534 3000
    Shot 'reader'
    Tap 540 1200 800
    Shot 'reader_toolbar'
    adb shell input keyevent KEYCODE_BACK | Out-Null
    Start-Sleep -Milliseconds 800

    if ($FreshLogin) {
        Shot 'login'
    } else {
        Tap $TabShelf $TabY 1200
    }
}
elseif ($Target -eq 'original') {
    if (-not (adb shell pm list packages $OrigPkg)) {
        Write-Warning "原包 $OrigPkg 未安装，请先 adb install 原始 APK"
        exit 1
    }
    adb shell am force-stop $OrigPkg | Out-Null
    Start-Sleep -Milliseconds 800
    # 冷启动：原包启动链路较重（加固 + 多引擎），等待时间放宽
    adb shell monkey -p $OrigPkg -c android.intent.category.LAUNCHER 1 | Out-Null
    Start-Sleep -Milliseconds 12000
    Shot 'launch_splash'
    Start-Sleep -Milliseconds 6000
    Shot 'home'
    # 书城 / 书架 / 我的：底部栏布局以首次采集截图为准再校准坐标
    Tap $TabStore $TabY 4000
    Shot 'bookcity'
    Tap $TabShelf $TabY 4000
    Shot 'bookshelf'
    Tap $TabMine $TabY 4000
    Shot 'mine'
}

Write-Host "采集完成：$OutDir"
