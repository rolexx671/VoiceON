#!/bin/bash
# Интеграционная проверка встроенной русской модели на синтезированной речи.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ARTIFACT="${1:-$REPO_DIR/dist/VoiceON.dmg}"
TEST_DIR=$(mktemp -d /tmp/voiceon-transcription-test.XXXXXX)
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
WHISPER_BIN="$APP/Contents/MacOS/whisper-cli"
MODEL="$APP/Contents/Resources/models/ggml-base.bin"
[ -x "$WHISPER_BIN" ] && [ -s "$MODEL" ] || { echo "Не найдены встроенный движок или базовая модель." >&2; exit 1; }
# Не загружаем голоса автоматически: используем уже установленный русский голос.
say -v '?' > "$TEST_DIR/voices.txt"
VOICE=$(awk '/[[:space:]]ru_[A-Z]+[[:space:]]/ {print $1; exit}' "$TEST_DIR/voices.txt")
if [ -z "$VOICE" ]; then
    echo "Проверка не выполнена: в macOS не установлен русский голос для синтеза речи." >&2
    echo "Добавьте русский голос в Системных настройках и повторите проверку." >&2
    exit 1
fi
echo "Создание русской тестовой записи голосом ${VOICE}…"
say -v "$VOICE" -o "$TEST_DIR/russian.aiff" 'Привет, это проверка голосового ввода на русском языке. Сегодня хорошая погода.'
afconvert -f WAVE -d LEI16@16000 -c 1 "$TEST_DIR/russian.aiff" "$TEST_DIR/russian.wav"
"$WHISPER_BIN" -m "$MODEL" -f "$TEST_DIR/russian.wav" -l ru -nt -mc 0 > "$TEST_DIR/result.txt" 2> "$TEST_DIR/engine.log"
if grep -Eiq 'проверка|голосового|русском|погода' "$TEST_DIR/result.txt"; then
    echo "Русская речь успешно распознана:"
    cat "$TEST_DIR/result.txt"
else
    echo "Ошибка: распознанный текст не содержит ожидаемых русских слов." >&2
    cat "$TEST_DIR/result.txt" >&2
    exit 1
fi
