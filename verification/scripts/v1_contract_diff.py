#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""V1 契约比对：原包 libapp.so 中的 ASCII 契约串 vs demo 侧实际声明的通道/方法/路由。

背景：
    原项目 Dart 侧代码不可还原（AOT 快照 + 360 加固），但 MethodChannel 的通道名、
    方法名、路由名都是 ASCII 常量，会原样保留在 libapp.so 的字符串池里，
    因此可以用“字符串存在性”作为接口契约的机器可核对证据。

产出：
    verification/contracts/original_contracts.json   原包侧提取结果
    verification/contracts/demo_contracts.json       demo 侧源码提取结果
    verification/contracts/v1_contract_report.md     人类可读的差异报告
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIBAPP = ROOT / "verification" / "evidence" / "libapp.so"
OUT_DIR = ROOT / "verification" / "contracts"

DEMO_KOTLIN = ROOT / "android_app/app/src/main/java/com/qidian/demo/presentation/flutter/BaseFlutterContainer.kt"
DEMO_DART = ROOT / "flutter_module/lib/services/native_bridge.dart"

# 原项目里已知/待确认的 Flutter 路由（用于存在性探针）
ROUTE_PROBES = [
    "/book_category",
    "/book_detail",
    "/mine",
    "/bookStore",
    "/search",
    "/bookshelf",
]

# 原项目已知的通道前缀（来自 BaseFlutterActivity 反编译 + 运行时日志）
CHANNEL_HINTS = [
    "com.yw.flutter.method_call",
    "com.yw.flutter.notify",
    "com.yw.flutter.book_detail",
    "com.yw.flutter_tardis.multi_engin_broadcast_channel",
]

PRINTABLE = re.compile(rb"[\x20-\x7e]{4,}")


def extract_ascii_strings(path: Path) -> set[str]:
    """从二进制里提取所有可打印 ASCII 串（长度 >= 4）。"""
    data = path.read_bytes()
    return {m.group(0).decode("ascii") for m in PRINTABLE.finditer(data)}


def collect_original(strings: set[str]) -> dict:
    joined = "\n".join(strings)

    def present(token: str) -> bool:
        return token in joined

    channels = sorted(s for s in strings if "com.yw" in s and len(s) < 120)
    route_like = sorted(
        s
        for s in strings
        if re.fullmatch(r"/[a-zA-Z][A-Za-z0-9_\-/]{0,40}", s)
        and not s.startswith(("/proc", "/sys", "/data", "/system", "/vendor", "/apex", "/dev", "/sdcard"))
    )
    # 方法名候选：Dart 侧传给 invokeMethod 的字符串通常以独立串存在
    method_tokens = sorted(
        s
        for s in strings
        if re.fullmatch(r"[a-zA-Z][A-Za-z0-9_]{3,40}", s)
        and s.lower().startswith(("get", "open", "set", "notify", "user", "flutter", "logout", "login", "refresh"))
    )
    probes = {name: present(name) for name in ROUTE_PROBES}
    return {
        "source": str(LIBAPP.relative_to(ROOT)),
        "ascii_string_count": len(strings),
        "channel_hints": {c: present(c) for c in CHANNEL_HINTS},
        "channels_found": channels,
        "route_probes": probes,
        "route_like": route_like[:200],
        "method_token_candidates": method_tokens[:200],
    }


KOTLIN_CHANNEL = re.compile(r'(?:const\s+val\s+CHANNEL_\w+|CHANNEL_\w+)\s*[:=]\s*"([^"]+)"')
KOTLIN_CONST_METHOD = re.compile(r'(?:private\s+)?const\s+val\s+METHOD_\w+\s*=\s*"([^"]+)"')
KOTLIN_WHEN = re.compile(r'"([A-Za-z][\w]*)"\s*->')
DART_CHANNEL = re.compile(r"MethodChannel\(\s*'([^']+)'")
DART_INVOKE = re.compile(r"invokeMethod<[^>]*>\(\s*'([^']+)'")
DART_INVOKE_PLAIN = re.compile(r"invokeMethod\(\s*'([^']+)'")
DART_INVOKE_HELPER = re.compile(r"_invoke<[^>]*>\(\s*'([^']+)'")
DART_CONST_METHOD = re.compile(r"const\s+String\s+_method\w+\s*=\s*'([^']+)'")
DART_CASE = re.compile(r"case\s+_?[A-Za-z_][\w]*:\s*")


def collect_demo() -> dict:
    kotlin = DEMO_KOTLIN.read_text(encoding="utf-8")
    dart = DEMO_DART.read_text(encoding="utf-8")

    channels = sorted(set(KOTLIN_CHANNEL.findall(kotlin)) | set(DART_CHANNEL.findall(dart)))
    methods = sorted(
        set(KOTLIN_CONST_METHOD.findall(kotlin))
        | set(KOTLIN_WHEN.findall(kotlin))
        | set(DART_INVOKE.findall(dart))
        | set(DART_INVOKE_PLAIN.findall(dart))
        | set(DART_INVOKE_HELPER.findall(dart))
        | set(DART_CONST_METHOD.findall(dart))
    )
    routes = sorted(set(re.findall(r'ROUTE_\w+\s*=\s*"([^"]+)"', kotlin)))
    # main.dart 的路由分发
    main_dart = ROOT / "flutter_module/lib/main.dart"
    if main_dart.exists():
        routes += sorted(set(re.findall(r"case\s+'([^']+)'", main_dart.read_text(encoding="utf-8"))))
    return {
        "source": [str(DEMO_KOTLIN.relative_to(ROOT)), str(DEMO_DART.relative_to(ROOT))],
        "channels": channels,
        "methods": methods,
        "routes": sorted(set(routes)),
    }


def build_report(original: dict, demo: dict) -> str:
    strings_joined = original.get("_joined", "")
    del original["_joined"]

    def head(status: str) -> str:
        return {"PASS": "✅ PASS", "WARN": "⚠️ WARN", "FAIL": "❌ FAIL"}[status]

    rows = []
    for ch in demo["channels"]:
        ok = ch in strings_joined
        rows.append(("通道", ch, "原包含该串" if ok else "原包未找到", "PASS" if ok else "FAIL"))
    for m in demo["methods"]:
        if m == "flutterReady":
            continue
        ok = m in strings_joined
        rows.append(("方法", m, "原包含该串" if ok else "原包未找到（可能是 demo 自增方法）", "PASS" if ok else "WARN"))
    for r in demo["routes"]:
        ok = r in strings_joined
        rows.append(("路由", r, "原包含该串" if ok else "原包未找到", "PASS" if ok else "WARN"))

    lines = [
        "# V1 接口契约比对报告",
        "",
        f"- 原包样本：`{original['source']}`",
        f"- 提取 ASCII 串：{original['ascii_string_count']} 条",
        f"- demo 来源：{' / '.join(demo['source'])}",
        "",
        "## 1. 已知通道存在性（原包）",
        "",
        "| 通道 | 原包是否存在 |",
        "| --- | --- |",
    ]
    for ch, ok in original["channel_hints"].items():
        lines.append(f"| `{ch}` | {'是' if ok else '否'} |")

    lines += ["", "## 2. 原包中出现的 `com.yw*` 字符串", ""]
    if original["channels_found"]:
        lines += [f"- `{c}`" for c in original["channels_found"]]
    else:
        lines.append("- 无")

    lines += ["", "## 3. 路由探针（原包）", "", "| 路由 | 是否存在 |", "| --- | --- |"]
    for r, ok in original["route_probes"].items():
        lines.append(f"| `{r}` | {'是' if ok else '否'} |")

    lines += ["", "## 4. demo 声明 vs 原包字符串", "", "| 类型 | 名称 | 原包证据 | 结论 |", "| --- | --- | --- | --- |"]
    for kind, name, note, status in rows:
        lines.append(f"| {kind} | `{name}` | {note} | {head(status)} |")

    fails = sum(1 for *_, s in rows if s == "FAIL")
    warns = sum(1 for *_, s in rows if s == "WARN")
    passes = sum(1 for *_, s in rows if s == "PASS")
    lines += [
        "",
        "## 5. 汇总",
        "",
        f"- PASS {passes} / WARN {warns} / FAIL {fails}",
        "",
        "> 说明：方法名 WARN 只代表该名未在 AOT 字符串池中以独立串出现（可能被内联或拼接），",
        "> 需要 V4 交互回归做运行时确认；通道名 FAIL 属于阻塞级，必须修复。",
    ]
    return "\n".join(lines) + "\n"


def main() -> int:
    if not LIBAPP.exists():
        print(f"未找到 {LIBAPP}", file=sys.stderr)
        return 2
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"读取 {LIBAPP} ...")
    strings = extract_ascii_strings(LIBAPP)
    print(f"提取 ASCII 串 {len(strings)} 条")

    original = collect_original(strings)
    demo = collect_demo()

    (OUT_DIR / "original_contracts.json").write_text(
        json.dumps(original, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    (OUT_DIR / "demo_contracts.json").write_text(
        json.dumps(demo, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    original["_joined"] = "\n".join(strings)
    report = build_report(original, demo)
    (OUT_DIR / "v1_contract_report.md").write_text(report, encoding="utf-8")
    print(report)
    print(f"已写出：{OUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
