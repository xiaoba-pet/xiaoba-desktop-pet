#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_ROOT="$ROOT/dist/小八.app"
CONTENTS="$APP_ROOT/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
BIN="$MACOS/xiaoba-bin"
CACHE_ROOT="$ROOT/.build/module-cache"
DEFAULT_SDK="$(xcrun --sdk macosx --show-sdk-path)"
COMPAT_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk"
SDK_PATH="$DEFAULT_SDK"

if [[ -d "$COMPAT_SDK" ]]; then
  SDK_PATH="$COMPAT_SDK"
fi

mkdir -p "$MACOS" "$RESOURCES" "$CACHE_ROOT/clang" "$CACHE_ROOT/swift"

env \
  CLANG_MODULE_CACHE_PATH="$CACHE_ROOT/clang" \
  SWIFT_MODULE_CACHE_PATH="$CACHE_ROOT/swift" \
  swiftc \
  -sdk "$SDK_PATH" \
  -target "$(uname -m)-apple-macosx13.0" \
  -O \
  -framework AppKit \
  -framework QuartzCore \
  -o "$BIN" \
  "$ROOT/Sources/XiaobaPet.swift"

cp "$ROOT/Assets/xiaoba.png" "$RESOURCES/xiaoba.png"

cat >"$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleExecutable</key>
  <string>xiaoba-bin</string>
  <key>CFBundleIdentifier</key>
  <string>local.xiaoba.desktop-pet</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>小八</string>
  <key>CFBundleDisplayName</key>
  <string>小八桌面宠物</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

plutil -lint "$CONTENTS/Info.plist" >/dev/null

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_ROOT" >/dev/null 2>&1 || true
fi

echo "$APP_ROOT"
