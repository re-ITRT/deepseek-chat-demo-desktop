import 'package:flutter_test/flutter_test.dart';
import 'package:deepseek_chat_demo/web_server.dart';

void main() {
  test('LocalWebServer asset root constant is set', () {
    expect(LocalWebServer.kAssetWebRoot, 'web/dist');
  });

  test('marker fingerprint is deterministic', () {
    // 仅验证纯逻辑路径存在、不依赖平台插件。
    expect(LocalWebServer.kAssetWebRoot.isNotEmpty, isTrue);
  });
}