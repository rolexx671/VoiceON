#!/bin/bash
# Подготовка локального выпуска. Публикация выполняется отдельно владельцем форка.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' "$REPO_DIR/Sources/OpenWisprLib/Version.swift")
if [ "$#" -gt 1 ] || { [ "$#" -eq 1 ] && [ "$1" != "$VERSION" ]; }; then
    echo "Использование: bash scripts/deploy.sh [$VERSION]" >&2
    echo "Версия должна совпадать с Sources/OpenWisprLib/Version.swift." >&2
    exit 1
fi
bash "$REPO_DIR/scripts/build-dmg.sh"
cat <<EOF
Выпуск VoiceON $VERSION подготовлен:
  $REPO_DIR/dist/VoiceON.dmg
  $REPO_DIR/dist/VoiceON.dmg.sha256

Для публикации откройте https://github.com/rolexx671/VoiceON/releases/new,
выберите тег v$VERSION, добавьте описание на русском и приложите оба файла.
Перед публикацией проверьте установку и голосовой ввод из готового образа.
EOF
