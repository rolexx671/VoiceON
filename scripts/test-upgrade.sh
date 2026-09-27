#!/bin/bash
# Замена двух готовых версий проверяется в отдельной временной папке.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OLD_ARTIFACT="${1:-$REPO_DIR/dist/VoiceON.dmg}"
NEW_ARTIFACT="${2:-$OLD_ARTIFACT}"
TEST_DIR=$(mktemp -d /tmp/voiceon-upgrade-test.XXXXXX)
MOUNTED_OLD=false
MOUNTED_NEW=false
cleanup() {
    local test_exit_status=$?
    if "$MOUNTED_NEW"; then hdiutil detach "$TEST_DIR/new-image" >/dev/null; fi
    if "$MOUNTED_OLD"; then hdiutil detach "$TEST_DIR/old-image" >/dev/null; fi
    rm -rf "$TEST_DIR"
    exit "$test_exit_status"
}
trap cleanup EXIT
resolve_app() {
    local artifact="$1" label="$2"
    case "$artifact" in
        *.dmg)
            mkdir "$TEST_DIR/$label-image"
            hdiutil attach -readonly -nobrowse -mountpoint "$TEST_DIR/$label-image" "$artifact" >/dev/null
            if [ "$label" = old ]; then MOUNTED_OLD=true; else MOUNTED_NEW=true; fi
            RESOLVED_APP="$TEST_DIR/$label-image/VoiceON.app"
            ;;
        *.app) RESOLVED_APP="$artifact" ;;
        *) echo "Укажите два образа .dmg или два приложения .app." >&2; exit 1 ;;
    esac
}
resolve_app "$OLD_ARTIFACT" old
OLD_APP="$RESOLVED_APP"
if [ "$NEW_ARTIFACT" = "$OLD_ARTIFACT" ]; then
    NEW_APP="$OLD_APP"
else
    resolve_app "$NEW_ARTIFACT" new
    NEW_APP="$RESOLVED_APP"
fi
bash "$REPO_DIR/scripts/test-install.sh" "$OLD_APP"
bash "$REPO_DIR/scripts/test-install.sh" "$NEW_APP"
mkdir "$TEST_DIR/Applications"
ditto "$OLD_APP" "$TEST_DIR/Applications/VoiceON.app"
# Удаляется только тестовая копия в каталоге, созданном выше через mktemp.
rm -rf "$TEST_DIR/Applications/VoiceON.app"
ditto "$NEW_APP" "$TEST_DIR/Applications/VoiceON.app"
codesign --verify --deep --strict "$TEST_DIR/Applications/VoiceON.app"
EXPECTED_VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$NEW_APP/Contents/Info.plist")
ACTUAL_VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$TEST_DIR/Applications/VoiceON.app/Contents/Info.plist")
[ "$ACTUAL_VERSION" = "$EXPECTED_VERSION" ] || { echo "Ошибка: после замены неверная версия." >&2; exit 1; }
echo "Замена приложения успешно проверена. Итоговая версия: $ACTUAL_VERSION."
echo "Сохранность разрешений macOS проверьте вручную после установки и первого запуска новой версии."
