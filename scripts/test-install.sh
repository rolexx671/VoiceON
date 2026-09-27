#!/bin/bash
# Проверка готового автономного приложения без установки.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACT="${1:-$REPO_DIR/dist/VoiceON.dmg}"
TEST_DIR=$(mktemp -d /tmp/voiceon-install-test.XXXXXX)
MOUNTED=false
cleanup() {
    local test_exit_status=$?
    if "$MOUNTED"; then hdiutil detach "$TEST_DIR/image" >/dev/null; fi
    rm -rf "$TEST_DIR"
    exit "$test_exit_status"
}
trap cleanup EXIT
case "$ARTIFACT" in
    *.dmg)
        mkdir "$TEST_DIR/image"
        hdiutil attach -readonly -nobrowse -mountpoint "$TEST_DIR/image" "$ARTIFACT" >/dev/null
        MOUNTED=true
        APP="$TEST_DIR/image/VoiceON.app"
        ;;
    *.app) APP="$ARTIFACT" ;;
    *) echo "Укажите путь к VoiceON.dmg или VoiceON.app." >&2; exit 1 ;;
esac
BIN="$APP/Contents/MacOS/voiceon"
PLIST="$APP/Contents/Info.plist"
PASS=0
check() {
    local description="$1"
    shift
    if "$@"; then PASS=$((PASS + 1)); echo "  Пройдено: $description";
    else echo "  Ошибка: $description" >&2; exit 1; fi
}
check "Исполняемый файл VoiceON" test -x "$BIN"
check "Встроенный движок распознавания" test -x "$APP/Contents/MacOS/whisper-cli"
check "Встроенная базовая модель" test -s "$APP/Contents/Resources/models/ggml-base.bin"
check "Встроенная модель определения речи" test -s "$APP/Contents/Resources/models/ggml-silero-v6.2.0.bin"
check "Корректный Info.plist" plutil -lint "$PLIST"
check "Идентификатор VoiceON" test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PLIST")" = com.voiceon.app
check "Русский язык приложения" test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDevelopmentRegion' "$PLIST")" = ru
check "Целостность подписи" codesign --verify --deep --strict "$APP"
"$BIN" --help > "$TEST_DIR/help.txt"
check "Справка на русском" grep -q 'Голосовой ввод' "$TEST_DIR/help.txt"
"$BIN" status > "$TEST_DIR/status.txt"
check "Состояние на русском" grep -q 'Настройки:' "$TEST_DIR/status.txt"
check "Движок доступен из приложения" grep -q 'whisper-cpp: да' "$TEST_DIR/status.txt"
"$BIN" get-hotkey > "$TEST_DIR/hotkey.txt"
check "Название клавиши на русском" grep -q 'Текущая клавиша:' "$TEST_DIR/hotkey.txt"
if "$BIN" set-hotkey несуществующая-клавиша > "$TEST_DIR/error.txt" 2>&1; then
    echo "Ошибка: несуществующая клавиша принята." >&2; exit 1
fi
check "Ошибка неизвестной клавиши на русском" grep -q 'неизвестная клавиша' "$TEST_DIR/error.txt"
echo "Проверок пройдено: $PASS."
