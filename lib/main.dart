import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_host.dart';
import 'app_host_linux.dart';
import 'web_server.dart';

/// DeepSeek Chat Demo — Flutter 原生外壳（Android APK / Linux DEB）。
///
/// 把 rspack 构建出的 chat-demo 静态页面（`web/dist`）打包进 Flutter 资产，
/// 起一个 127.0.0.1 本地 HTTP 服务器托管，再交给所在平台的系统 WebView 显示：
///   * Android  → webview_flutter（内嵌 WebView）
///   * Linux    → desktop_webview_window（WebKitGTK 窗口）
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && Platform.isLinux) {
    await runLinux();
    return;
  }

  runApp(const ChatDemoApp());
}

/// Linux：启动本地服务器，打开系统 WebKit 窗口，保持事件循环直到窗口关闭。
Future<void> runLinux() async {
  final server = LocalWebServer();
  await server.start();

  final closed = Completer<void>();
  var opened = false;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Builder(builder: (context) {
            // 等第一帧拿到 SchedulerBinding 说明 Flutter 引擎已就绪，
            // 再创建 WebView 窗口，避免插件通道尚未注册导致 MissingPluginException。
            if (!opened) {
              opened = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                try {
                  await openLinuxWebView(
                    url: server.baseUrl,
                    title: 'DeepSeek Chat Demo',
                    onExit: () async {
                      await server.stop();
                      if (!closed.isCompleted) closed.complete();
                    },
                  );
                } catch (e, st) {
                  debugPrint('openLinuxWebView failed: $e\n$st');
                  if (!closed.isCompleted) closed.complete();
                }
              });
            }
            return const SizedBox.shrink();
          }),
        ),
      ),
    ),
  );

  await closed.future;
}

/// Android / 其它：内嵌 WebView 的 Flutter 界面。
class ChatDemoApp extends StatelessWidget {
  const ChatDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepSeek Chat Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4D6BFE)),
        useMaterial3: true,
      ),
      home: const AppHost(),
    );
  }
}