import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

/// 把 Flutter 打包进来的 `web/dist`（chat-demo 静态页面）解压到应用本地数据目录，
/// 再起一个 127.0.0.1 本地 HTTP 服务器来托管它。
///
/// 用本地 HTTP 而非 `file://` 的原因：chat-demo 依赖 localStorage / IndexedDB
/// 持久化会话与附件，它们按 origin（协议+主机+端口）隔离；只有稳定的本地 origin
/// 才能保证聊天记录可靠保存在设备上。对外基地址为 `http://127.0.0.1:<port>`。
class LocalWebServer {
  /// Flutter asset 里打包的静态站点根目录。
  static const String kAssetWebRoot = 'web/dist';

  HttpServer? _server;
  int _port = 0;
  bool _started = false;

  /// 当前本地服务器基地址，如 http://127.0.0.1:34567/
  String get baseUrl => 'http://127.0.0.1:$_port/';

  bool get started => _started;

  int get port => _port;

  Future<void> start() async {
    if (_started) return;

    final base = await getApplicationSupportDirectory();
    final webDir = Directory(p.join(base.path, 'web_dist'));
    await webDir.create(recursive: true);

    // 把 Flutter 资产解压一次到磁盘。
    await _extractAssetTree(webDir);

    final handler = _buildHandler(webDir);
    _server = await shelf_io.serve(
      handler,
      InternetAddress.loopbackIPv4,
      0, // 端口 0 => 系统分配空闲端口
    );
    _port = _server!.port;
    _started = true;
    // ignore: avoid_print
    print('[web] local server on $baseUrl');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _started = false;
    _port = 0;
  }

  /// 静态文件 + SPA 回退（非文件路径都落到 index.html）。
  Handler _buildHandler(Directory webDir) {
    final staticHandler = createStaticHandler(
      webDir.path,
      defaultDocument: 'index.html',
    );

    return (Request request) async {
      if (request.method != 'GET' && request.method != 'HEAD') {
        return Response(405, body: 'Method Not Allowed');
      }

      final relPath = request.url.path;
      // 根路径或目录路径 -> index.html
      if (relPath.isEmpty || relPath.endsWith('/')) {
        return _serveIndex(webDir);
      }

      final target = File(p.join(webDir.path, relPath));
      if (await target.exists()) {
        return staticHandler(request);
      }

      // SPA 未知路径：回退到 index.html（保持浏览器端路由）。
      return _serveIndex(webDir);
    };
  }

  Future<Response> _serveIndex(Directory webDir) async {
    final indexFile = File(p.join(webDir.path, 'index.html'));
    if (!await indexFile.exists()) {
      return Response.notFound('index.html not found');
    }
    final bytes = await indexFile.readAsBytes();
    return Response.ok(bytes, headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'no-store',
      'content-length': '${bytes.length}',
    });
  }

  /// 递归把 Flutter asset 目录 `web/dist` 里的文件写到本地 `webDir`。
  ///
  /// 只在文件缺失或内容不同时写盘，避免每次启动都全量重写。
  Future<void> _extractAssetTree(Directory webDir) async {
    final keys = await _assetKeys();
    if (keys.isEmpty) {
      throw StateError('no web assets bundled: $kAssetWebRoot missing');
    }

    final marker = File(p.join(webDir.path, '.extracted_marker'));
    final markerSrc = '${keys.length}:${_manifestFingerprint(keys)}';
    if (await marker.exists() && await marker.readAsString() == markerSrc) {
      // ignore: avoid_print
      print('[web] assets already extracted (${keys.length} files)');
      return;
    }

    for (final key in keys) {
      final rel = key.substring(kAssetWebRoot.length + 1);
      final data = await rootBundle.load(key);
      final out = File(p.join(webDir.path, rel));
      await out.parent.create(recursive: true);
      await out.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    await marker.writeAsString(markerSrc);
    // ignore: avoid_print
    print('[web] extracted ${keys.length} assets to ${webDir.path}');
  }

  /// 从 AssetManifest 里筛出 `web/dist/` 开头的资产键。
  ///
  /// 用官方 [AssetManifest.loadFromAssetBundle] 精确枚举，避免手写解析二进制清单。
  Future<List<String>> _assetKeys() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest.listAssets()
        .where((k) => k.startsWith('$kAssetWebRoot/'))
        .toList()..sort();
  }

  String _manifestFingerprint(List<String> keys) =>
      keys.fold<int>(0, (acc, k) => acc + k.length).toString();
}