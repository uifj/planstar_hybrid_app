import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/bridge_protocol.dart';
import '../../services/native_bridge.dart';

/// 我的页（对应原生 app 中的 MineHistoryFlutterActivity / 我的 Tab）。
/// 通过 MethodChannel 读取原生 MMKV 中的登录态。
///
/// 登录态由原生主动推送（[NativeBridge.loginState]），
/// 不再依赖 onResume 时的跨端轮询，前后台切换少一次通道往返。
class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  Map<String, dynamic>? _userInfo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    NativeBridge.loginState.addListener(_onLoginStateChanged);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    // 移除监听，避免页面销毁后仍触发 setState
    NativeBridge.loginState.removeListener(_onLoginStateChanged);
    super.dispose();
  }

  void _onLoginStateChanged() {
    // 推送只带登录状态，不带昵称/token，所以状态变化后回查一次资料
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final info = await NativeBridge.getUserInfo();
    if (!mounted) return;
    final loggedIn = info?[BridgeProtocol.keyLoggedIn] == true;
    setState(() {
      _userInfo = loggedIn ? info : null;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    try {
      await NativeBridge.logout();
    } on BridgeException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('退出登录失败：${error.code}')));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已退出登录')));
  }

  Future<void> _openLogin() async {
    try {
      await NativeBridge.openLogin();
    } on BridgeException catch (error) {
      // 登录页由原生实现，唤起失败保持当前游客态即可
      debugPrint('openLogin failed: ${error.code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('我的'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildUserCard(),
                const SizedBox(height: 8),
                _buildMenuGroup(),
              ],
            ),
    );
  }

  Widget _buildUserCard() {
    final loggedIn = _userInfo != null;
    final nickname = _userInfo?[BridgeProtocol.keyNickname] as String? ?? '';
    final token = _userInfo?[BridgeProtocol.keyToken] as String? ?? '';
    final maskedToken = token.length > 8
        ? '${token.substring(0, 4)}****${token.substring(token.length - 4)}'
        : (token.isEmpty ? '未登录' : token);

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Text(
              loggedIn && nickname.isNotEmpty ? nickname.characters.first : '客',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: loggedIn
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Token: $maskedToken',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    '登录后开启全部功能',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
          ),
          if (!loggedIn)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
              ),
              onPressed: _openLogin,
              child: const Text('登录'),
            )
          else
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
              onPressed: _logout,
              child: const Text('退出'),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuGroup() {
    const menus = [
      (Icons.collections_bookmark_outlined, '我的书架'),
      (Icons.history, '阅读历史'),
      (Icons.account_balance_wallet_outlined, '我的钱包'),
      (Icons.notifications_none, '消息通知'),
      (Icons.settings_outlined, '设置'),
    ];
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          for (var i = 0; i < menus.length; i++)
            ListTile(
              leading: Icon(menus[i].$1, color: AppColors.primary),
              title: Text(
                menus[i].$2,
                style: const TextStyle(fontSize: AppTextSize.body),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('${menus[i].$2}（演示页）')));
              },
            ),
        ],
      ),
    );
  }
}
