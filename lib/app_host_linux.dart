import 'dart:async';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 是否 Linux 平台。
bool get isLinux => !kIsWeb && Platform.isLinux;

/// Linux 占位视图：WebWiew 走独立原生窗口，Flutter 窗口仅作后备。
Widget buildPlaceholder(BuildContext context) {
  return const Scaffold(
    body: Center(child: Text('正在打开 WebView 窗口…')),
  );
}

/// 打开一个由系统 WebKitGTK 驱动的 webview 窗口并加载 [url]。
/// 窗口标题为 [title]，关闭时回调 [onExit]。
Future<Webview> openLinuxWebView({
  required String url,
  required String title,
  Future<void> Function()? onExit,
}) async {
  final webview = await WebviewWindow.create(
    configuration: CreateConfiguration(
      windowWidth: 1200,
      windowHeight: 820,
      title: title,
    ),
  );

  webview.onClose.whenComplete(() {
    onExit?.call();
  });

  webview.launch(url);
  return webview;
}