#!/bin/bash
set -euo pipefail

if [ "$#" -gt 0 ]; then
    printf '%s\n' 'Использование: bash scripts/uninstall.sh' 'Приложение VoiceON будет перемещено в Корзину после подтверждения.' 'Настройки, модели и история в ~/.config/voiceon сохраняются.'
    case "$1" in --help|-h) exit 0 ;; *) exit 1 ;; esac
fi

apps=()
for app in "$HOME/Applications/VoiceON.app" "/Applications/VoiceON.app"; do
    if [ -d "$app" ] && [ ! -L "$app" ]; then
        bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null || true)
        if [ "$bundle_id" = "com.voiceon.app" ]; then
            apps+=("$app")
        else
            printf 'Пропущено: %s — не удалось подтвердить, что это приложение VoiceON.\n' "$app"
        fi
    fi
done

if [ "${#apps[@]}" -eq 0 ]; then
    printf '%s\n' 'Установленное приложение VoiceON не найдено.' 'Настройки и история сохранены.'
    exit 0
fi

printf '%s\n' 'Сначала завершите VoiceON через значок в строке меню.' 'В Корзину будут перемещены:'
printf '  %s\n' "${apps[@]}"
printf '%s\n' 'Настройки, модели и история в ~/.config/voiceon сохранятся.'
printf 'Для подтверждения введите УДАЛИТЬ: '
confirmation=''
if ! IFS= read -r confirmation || [ "$confirmation" != 'УДАЛИТЬ' ]; then
    printf '%s\n' 'Удаление отменено.'
    exit 0
fi

mkdir -p "$HOME/.Trash"
for app in "${apps[@]}"; do
    trash_path="$HOME/.Trash/VoiceON-$(date +%Y%m%d-%H%M%S)-$$.app"
    suffix=0
    while [ -e "$trash_path" ]; do
        suffix=$((suffix + 1))
        trash_path="$HOME/.Trash/VoiceON-$(date +%Y%m%d-%H%M%S)-$$-$suffix.app"
    done
    if mv "$app" "$trash_path"; then
        printf 'Перемещено в Корзину: %s\n' "$app"
    else
        printf 'Не удалось переместить %s. Закройте приложение и переместите его в Корзину через Finder.\n' "$app" >&2
        exit 1
    fi
done
printf '%s\n' 'VoiceON удалён. Настройки и история сохранены.' 'Чтобы восстановить приложение, верните его из Корзины или откройте VoiceON.dmg.'
