#!/usr/bin/env bash
# 把 flutter build linux --release 的 bundle 打包成 .deb
set -euo pipefail

APP_NAME="deepseek-chat-demo"
DISPLAY_NAME="DeepSeek Chat Demo"
MAINTAINER="re-ITRT <1940428933@qq.com>"
DESC="基于 DeepSeek API 的聊天示例（Flutter 原生封装），内嵌 chat-demo Web 应用。"
HOMEPAGE="https://github.com/re-ITRT/deepseek-chat-demo"
VERSION="${VERSION:-1.0.0}"
ARCH="amd64"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE="$REPO_ROOT/build/linux/x64/release/bundle"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

if [ ! -x "$BUNDLE/deepseek_chat_demo" ]; then
  echo "错误：找不到 Linux release bundle，请先运行 flutter build linux --release" >&2
  exit 1
fi

DEB="$REPO_ROOT/dist_pkg/deepseek-chat-demo_${VERSION}_${ARCH}.deb"
PKGDIR="$STAGE/deepseek-chat-demo"
mkdir -p "$PKGDIR/DEBIAN"
mkdir -p "$PKGDIR/usr/lib/deepseek-chat-demo/data" "$PKGDIR/usr/lib/deepseek-chat-demo/lib"
mkdir -p "$PKGDIR/usr/bin" "$PKGDIR/usr/share/applications" "$PKGDIR/usr/share/icons/hicolor/512x512/apps"

# 1) 控制文件
cat > "$PKGDIR/DEBIAN/control" <<EOF
Package: $APP_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: $MAINTAINER
Depends: libgtk-3-0 (>= 3.24), libwebkit2gtk-4.1-0, libsoup-3.0-0, libjavascriptcoregtk-4.1-0, libglib2.0-0
Description: $DESC
Homepage: $HOMEPAGE
EOF

# 2) 二进制 + 运行时库 + 数据
cp -a "$BUNDLE/deepseek_chat_demo" "$PKGDIR/usr/lib/deepseek-chat-demo/"
cp -a "$BUNDLE/data/flutter_assets" "$PKGDIR/usr/lib/deepseek-chat-demo/data/"
# 把插件 .so 装进 lib/（deepseek_chat_demo 运行时会按 $ORIGIN/lib 找）
if [ -d "$BUNDLE/lib" ]; then
  cp -a "$BUNDLE"/lib/*.so "$PKGDIR/usr/lib/deepseek-chat-demo/lib/" 2>/dev/null || true
fi

# 3) 启动封装
cat > "$PKGDIR/usr/bin/deepseek-chat-demo" <<'LAUNCHER'
#!/bin/sh
exec /usr/lib/deepseek-chat-demo/deepseek_chat_demo "$@"
LAUNCHER
chmod +x "$PKGDIR/usr/bin/deepseek-chat-demo"

# 4) 桌面入口
cat > "$PKGDIR/usr/share/applications/deepseek-chat-demo.desktop" <<EOF
[Desktop Entry]
Name=$DISPLAY_NAME
Comment=DeepSeek API 聊天示例
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Network;Chat;
StartupNotify=false
EOF

# 5) 图标（用内置 launcher 图标占位）
ICON_SRC="$REPO_ROOT/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$PKGDIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
fi

# 6) 打包
chmod -R a+rX "$PKGDIR"
mkdir -p "$REPO_ROOT/dist_pkg"
dpkg-deb --build --root-owner-group "$PKGDIR" "$DEB"
echo "✅ 生成 $DEB"
dpkg-deb --info "$DEB" | head -20