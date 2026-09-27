#!/usr/bin/env bash
# Статистика относится только к русскому форку VoiceON.
set -euo pipefail
REPO="rolexx671/VoiceON"
command -v gh >/dev/null || { echo "Для просмотра статистики нужна команда gh и вход в GitHub." >&2; exit 1; }
echo "Статистика VoiceON"
gh api "repos/$REPO" --jq '"Создан: \(.created_at[:10])\nЗвёзды: \(.stargazers_count)\nФорки: \(.forks_count)\nПодписчики: \(.subscribers_count)\nОткрытые обращения: \(.open_issues_count)"'
echo
echo "Загрузки файлов по выпускам:"
gh api --paginate "repos/$REPO/releases" --jq '.[] | "\(.tag_name): \([.assets[].download_count] | add // 0)"'
for metric in clones views; do
    if [ "$metric" = clones ]; then
        echo; echo "Клонирования за последние 14 дней:"
    else
        echo; echo "Просмотры за последние 14 дней:"
    fi
    if ! gh api "repos/$REPO/traffic/$metric" --jq '"Всего: \(.count), уникальных: \(.uniques)"' 2>/dev/null; then
        echo "Статистика трафика недоступна: необходимы права владельца репозитория."
    fi
done
