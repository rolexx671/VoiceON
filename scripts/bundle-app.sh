#!/bin/bash
set -euo pipefail

BINARY="${1:-.build/release/open-wispr}"
APP_DIR="${2:-VoiceON.app}"
VERSION="${3:-1.0.0}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
WHISPER_BINARY="${VOICEON_WHISPER_BINARY:-$REPO_DIR/.build/vendor/whisper-build/bin/whisper-cli}"
MODELS_DIR="${VOICEON_MODELS_DIR:-$REPO_DIR/.build/models}"

if [ ! -x "$BINARY" ] || [ ! -x "$WHISPER_BINARY" ] || [ ! -f "$MODELS_DIR/ggml-base.bin" ] || [ ! -f "$MODELS_DIR/ggml-silero-v6.2.0.bin" ]; then
    echo "Не найдены компоненты сборки. Сначала выполните: bash scripts/build-dmg.sh" >&2
    exit 1
fi
case "$APP_DIR" in
    *.app) ;;
    *) echo "Каталог приложения должен иметь расширение .app" >&2; exit 1 ;;
esac
if [ -e "$APP_DIR" ]; then
    echo "Каталог $APP_DIR уже существует. Укажите новый путь или удалите предыдущую сборку вручную." >&2
    exit 1
fi
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources/models" "$APP_DIR/Contents/Resources/ru.lproj" "$APP_DIR/Contents/Resources/Licenses"
cp "$BINARY" "$APP_DIR/Contents/MacOS/voiceon"
cp "$WHISPER_BINARY" "$APP_DIR/Contents/MacOS/whisper-cli"
cp "$REPO_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$MODELS_DIR/ggml-base.bin" "$MODELS_DIR/ggml-silero-v6.2.0.bin" "$APP_DIR/Contents/Resources/models/"
cp "$REPO_DIR/LICENSE" "$APP_DIR/Contents/Resources/Licenses/OpenWispr-MIT.txt"
cp "$REPO_DIR/.build/vendor/whisper.cpp/LICENSE" "$APP_DIR/Contents/Resources/Licenses/whisper.cpp-MIT.txt"
cp "$REPO_DIR/Resources/ThirdPartyNotices.ru.txt" "$APP_DIR/Contents/Resources/Licenses/"
cp "$REPO_DIR/Resources/Whisper-LICENSE.txt" "$REPO_DIR/Resources/Silero-LICENSE.txt" "$APP_DIR/Contents/Resources/Licenses/"
cp "$REPO_DIR/Resources/Инструкция.txt" "$APP_DIR/Contents/Resources/"

cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key><string>voiceon</string>
    <key>CFBundleIdentifier</key><string>com.voiceon.app</string>
    <key>CFBundleName</key><string>VoiceON</string>
    <key>CFBundleDisplayName</key><string>VoiceON</string>
    <key>CFBundleVersion</key><string>${VERSION}</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleDevelopmentRegion</key><string>ru</string>
    <key>CFBundleLocalizations</key><array><string>ru</string></array>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSArchitecturePriority</key><array><string>arm64</string></array>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSMicrophoneUsageDescription</key><string>VoiceON использует микрофон для распознавания вашей речи. Звук обрабатывается на этом Mac.</string>
    <key>NSHumanReadableCopyright</key><string>VoiceON — русская версия OpenWispr. Лицензия MIT.</string>
</dict></plist>
PLIST
cat > "$APP_DIR/Contents/Resources/ru.lproj/InfoPlist.strings" <<'STRINGS'
"CFBundleDisplayName" = "VoiceON";
"NSMicrophoneUsageDescription" = "VoiceON использует микрофон для распознавания вашей речи. Звук обрабатывается на этом Mac.";
STRINGS
# Встроенные компоненты подписываются раньше основного приложения.
codesign --force --sign - "$APP_DIR/Contents/MacOS/whisper-cli"
codesign --force --sign - --identifier com.voiceon.app "$APP_DIR"
codesign --verify --deep --strict "$APP_DIR"
echo "Приложение собрано: $APP_DIR"
