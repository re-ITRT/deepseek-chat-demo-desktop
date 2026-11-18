import 'dart:async';

import 'package:flutter/material.dart';

import 'web_server.dart';
import 'app_host_android.dart' as android_impl;
import 'app_host_linux.dart' as linux_impl;

/// 平台承载视图：
///   * Android  → webview_flutter 内嵌 WebView
///   * Linux    → desktop_webview_window（WebKitGTK 独立窗口）
///
/// 两个插件都在 pubspec 里声明，但各自只在对应平台被 native 编译与调用，
/// 跨平台时仅做运行时判断，绝不越界调用。
class AppHost extends StatefulWidget {
  const AppHost({super.key});

  @override
  State<AppHost> createState() => _AppHostState();
}

class _AppHostState extends State<AppHost> {
  final LocalWebServer _server = LocalWebServer();
  late final Future<void> _boot = _server.start();

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _boot,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootScreen();
        }
        if (snapshot.hasError) {
          return _ErrorPane(error: snapshot.error.toString());
        }
        if (android_impl.isAndroid) {
          return android_impl.buildWebView(context, _server);
        }
        if (linux_impl.isLinux) {
          return linux_impl.buildPlaceholder(context);
        }
        return _ErrorPane(error: '不支持的平台');
      },
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在启动本地服务…'),
          ],
        ),
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text('启动失败'),
              const SizedBox(height: 8),
              Text(error, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}