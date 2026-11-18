import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'web_server.dart';

/// 是否 Android 平台。
bool get isAndroid => !kIsWeb && Platform.isAndroid;

/// 用 webview_flutter 内嵌 WebView 展示本地服务器承载的 chat-demo。
Widget buildWebView(BuildContext context, LocalWebServer server) {
  return _AndroidWebView(server: server);
}

class _AndroidWebView extends StatefulWidget {
  const _AndroidWebView({required this.server});
  final LocalWebServer server;

  @override
  State<_AndroidWebView> createState() => _AndroidWebViewState();
}

class _AndroidWebViewState extends State<_AndroidWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36 deepseek-chat-demo',
      )
      ..loadRequest(Uri.parse(widget.server.baseUrl));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}