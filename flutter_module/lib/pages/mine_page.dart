import 'dart:async';

import 'package:flutter/material.dart';

import '../services/native_bridge.dart';

/// 我的页（对应原生 app 中的 MineHistoryFlutterActivity / 我的 Tab）。
/// 通过 MethodChannel 读取原生 MMKV 中的登录态。
///
/// 登录态由原生主动推送（[NativeBridge.loginStateChanges]），
/// 不再依赖 onResume 时的跨端轮询，前后台切换少一次通道往返。
class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  Map<String, dynamic>? _userInfo;
  bool _loading = true;
  StreamSubscription<Map<String, dynamic>>? _loginStateSub;

  @override
  void initState() {
    super.initState();
    // 订阅位置在 initState，取消在 dispose：页面销毁后不会再 setState
    _loginStateSub = NativeBridge.loginStateChanges.listen(_applyLoginState);
    _refresh();
  }

  @override
  void dispose() {
    _loginStateSub?.cancel();
    _loginStateSub = null;
    super.dispose();
  }

  void _applyLoginState(Map<String, dynamic> payload) {
    if (!mounted) return;
    setState(() {
      _userInfo = payload['loggedIn'] == true ? payload : null;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final info = await NativeBridge.getUserInfo();
    if (!mounted) return;
    setState(() {
      _userInfo = info;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    // 原生清空登录态后会主动推送 onLoginStateChanged，这里只负责交互反馈
    await NativeBridge.logout();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已退出登录')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5353E),
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
    final nickname = _userInfo?['nickname'] as String? ?? '';
    final token = _userInfo?['token'] as String? ?? '';
    final maskedToken = token.length > 8
        ? '${token.substring(0, 4)}****${token.substring(token.length - 4)}'
        : (token.isEmpty ? '未登录' : token);

    return Container(
      color: const Color(0xFFE5353E),
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
                color: Color(0xFFE5353E),
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
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                foregroundColor: const Color(0xFFE5353E),
              ),
              onPressed: () {
                // 登录结果由原生推回（loginStateChanges），这里不再重复请求
                NativeBridge.openLogin();
              },
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
              leading: Icon(menus[i].$1, color: const Color(0xFFE5353E)),
              title: Text(menus[i].$2, style: const TextStyle(fontSize: 15)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${menus[i].$2}（演示页）')),
                );
              },
            ),
        ],
      ),
    );
  }
}
