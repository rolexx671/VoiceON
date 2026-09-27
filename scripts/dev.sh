#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

printf '%s\n' 'Сборка VoiceON для разработки'
if [ "$(uname -s)" != 'Darwin' ]; then
    printf '%s\n' 'Для сборки требуется macOS.' >&2
    exit 1
fi
if [ -e 'VoiceON.app' ]; then
    printf '%s\n' 'Каталог VoiceON.app уже существует. Переместите предыдущую сборку, прежде чем запускать скрипт снова.' >&2
    exit 1
fi

printf '%s\n' 'Компиляция приложения…'
swift build -c release
printf '%s\n' 'Подготовка приложения и встроенного движка…'
bash scripts/bundle-app.sh .build/release/open-wispr VoiceON.app 1.0.0

printf '%s\n' 'Запуск VoiceON…' 'Настройки можно изменить через значок VoiceON в строке меню.' 'Для завершения нажмите Ctrl+C или выберите «Выйти из VoiceON».'
exec "$REPO_DIR/VoiceON.app/Contents/MacOS/voiceon" start
