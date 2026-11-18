# DeepSeek Chat Demo — Flutter 原生封装

把 [deepseek-ai/chat-demo](https://github.com/deepseek-ai/chat-demo)（基于 DeepSeek API 的静态聊天 Web 应用）封装成 **Flutter 原生桌面 / 移动应用**：

- **Android** → `.apk`（`webview_flutter` 内嵌 WebView）
- **Linux**   → `.deb`（WebKitGTK 窗口）

开箱即用，无需自建后端——直接在设置里填入你的 DeepSeek API Key 即可开始对话。

## ✨ 特性

- 完整的 chat-demo 全部功能：**多会话、流式回答、深度思考、智能搜索、语音输入/朗读、Markdown/公式/图表渲染**、历史导入导出、中英双语、深浅主题。
- 本地静态资源由应用内 127.0.0.1 HTTP 服务托管，会话与附件持久化到本地 origin，真正的离线可用（登录 API 后）。
- 原生外壳体积小、启动快，无浏览器/Node 运行时依赖。

## 📦 安装包

| 平台 | 产物 | 说明 |
| --- | --- | --- |
| Android | `deepseek-chat-demo-<ver>.apk` | 见 [Releases](../../releases) |
| Linux x64 | `deepseek-chat-demo_<ver>_amd64.deb` | 见 [Releases](../../releases)，依赖系统 WebKitGTK 4.1 |

> Linux 需要 `libwebkit2gtk-4.1-0`、`libsoup-3.0-0` 运行时（Ubuntu 24.04+ 自带）。

## 🚀 从源码构建

前置：Node 22.12+、pnpm、Flutter 3.4x（含 Linux 桌面工具链；构建 APK 还需 Android SDK 36 / NDK 28）。

```sh
# 1) 取上游 chat-demo，构建静态站点
git clone https://github.com/deepseek-ai/chat-demo.git
cd chat-demo && pnpm install && pnpm build    # 产出 dist/

# 2) 把静态站点放进本仓库的 Flutter 资产
cp -r chat-demo/dist/* flutter_app/web/dist/

# 3) 构建 APK（Android）
cd flutter_app
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk

# 4) 构建 Linux 桌面应用并打包 .deb
flutter build linux --release
./scripts/package_deb.sh
# 产物：deepseek-chat-demo_<ver>_amd64.deb
```

## 🗂 目录结构

```text
flutter_app/
  lib/
    main.dart              应用入口（平台分流）
    app_host.dart          平台承载视图
    app_host_android.dart  Android WebView（webview_flutter）
    app_host_linux.dart    Linux WebKit 窗口（desktop_webview_window）
    web_server.dart        本地 HTTP 静态资源服务器
  web/dist/                上游 chat-demo 构建产物（见 LICENSE）
  android/                 Android 工程
  linux/                   Linux 桌面工程
  scripts/package_deb.sh   .deb 打包脚本
```

## 📄 许可证

- 本项目（Flutter 封装层）采用 [MIT](LICENSE)。
- 内嵌的 `web/dist` 来源于 [deepseek-ai/chat-demo](https://github.com/deepseek-ai/chat-demo)（MIT），其 `LICENSE` 一并随包分发。
- 第三方依赖遵循各自许可证。

> 本项目与 DeepSeek 官方无附属关系。请自行保管 API Key，遵守 [DeepSeek 平台服务条款](https://platform.deepseek.com)。