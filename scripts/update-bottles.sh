#!/bin/bash
# Сохранённое имя команды объясняет переход от Homebrew к автономному приложению.
set -euo pipefail
cat <<'EOF'
VoiceON распространяется как автономный образ VoiceON.dmg.
Пакеты Homebrew (bottles) и отдельный репозиторий формулы больше не используются.

Чтобы собрать приложение с движком и моделями распознавания:
  bash scripts/build-dmg.sh

Чтобы подготовить локальный выпуск:
  bash scripts/deploy.sh
EOF
