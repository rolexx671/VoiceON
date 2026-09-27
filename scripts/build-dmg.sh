#!/bin/bash
# Автономная сборка VoiceON для Apple Silicon. Нужны Swift, Git и CMake.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"
if [ "$(uname -s)" != Darwin ] || [ "$(uname -m)" != arm64 ]; then
    echo "Эта сборка предназначена для macOS на Apple Silicon." >&2; exit 1
fi
for tool in swift cmake git curl hdiutil codesign; do
    command -v "$tool" >/dev/null || { echo "Для сборки не найдена команда: $tool" >&2; exit 1; }
done
VERSION=$(sed -n 's/.*version = "\([^"]*\)".*/\1/p' Sources/OpenWisprLib/Version.swift)
WHISPER_COMMIT=927cfce34f31707e17f2bff35c349632fb9e2c3a
WHISPER_SOURCE="$REPO_DIR/.build/vendor/whisper.cpp"
WHISPER_BUILD="$REPO_DIR/.build/vendor/whisper-build"
MODELS_DIR="$REPO_DIR/.build/models"
mkdir -p "$REPO_DIR/.build/vendor" "$MODELS_DIR" "$REPO_DIR/dist"
if [ ! -d "$WHISPER_SOURCE/.git" ]; then
    git clone --depth 1 --branch v1.9.4 https://github.com/ggml-org/whisper.cpp.git "$WHISPER_SOURCE"
fi
if [ "$(git -C "$WHISPER_SOURCE" rev-parse HEAD)" != "$WHISPER_COMMIT" ]; then
    echo "Версия исходников whisper.cpp не совпадает с закреплённой." >&2; exit 1
fi

echo "Сборка встроенного движка распознавания…"
cmake -S "$WHISPER_SOURCE" -B "$WHISPER_BUILD" \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
    -DBUILD_SHARED_LIBS=OFF -DGGML_NATIVE=OFF -DGGML_CPU_ARM_ARCH=armv8.2-a+dotprod \
    -DGGML_BLAS=OFF -DGGML_METAL=ON -DGGML_METAL_EMBED_LIBRARY=ON \
    -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_EXAMPLES=ON -DWHISPER_CURL=OFF
cmake --build "$WHISPER_BUILD" --config Release --target whisper-cli -j "$(sysctl -n hw.logicalcpu)"

fetch_model() {
    local name="$1" url="$2" expected="$3" actual
    if [ ! -f "$MODELS_DIR/$name" ]; then
        echo "Загрузка модели $name…"
        curl --fail --location --retry 3 --output "$MODELS_DIR/$name.download" "$url"
        actual=$(shasum -a 256 "$MODELS_DIR/$name.download" | awk '{print $1}')
        [ "$actual" = "$expected" ] || { echo "Контрольная сумма модели не совпадает: $name" >&2; exit 1; }
        mv "$MODELS_DIR/$name.download" "$MODELS_DIR/$name"
    fi
    actual=$(shasum -a 256 "$MODELS_DIR/$name" | awk '{print $1}')
    [ "$actual" = "$expected" ] || { echo "Повреждена модель: $name" >&2; exit 1; }
}
fetch_model ggml-base.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin \
    60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe
fetch_model ggml-silero-v6.2.0.bin https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v6.2.0.bin \
    2aa269b785eeb53a82983a20501ddf7c1d9c48e33ab63a41391ac6c9f7fb6987

echo "Сборка приложения…"
swift build --build-system native -c release
BINARY_DIR=$(swift build --build-system native -c release --show-bin-path)
STAGE=$(mktemp -d "$REPO_DIR/dist/.voiceon-stage.XXXXXX")
trap 'rm -rf "$STAGE"' EXIT
bash "$SCRIPT_DIR/bundle-app.sh" "$BINARY_DIR/open-wispr" "$STAGE/VoiceON.app" "$VERSION"
# Приложение не должно зависеть от каталогов разработчика и Homebrew.
if otool -L "$STAGE/VoiceON.app/Contents/MacOS/whisper-cli" | tail -n +2 | grep -Ev '^[[:space:]]*(/System/Library/|/usr/lib/)' | grep -q .; then
    echo "В движке обнаружена внешняя несистемная зависимость." >&2; exit 1
fi
ln -s /Applications "$STAGE/Программы"
cp "$REPO_DIR/Resources/Инструкция.txt" "$STAGE/Прочитайте перед запуском.txt"
echo "Создание VoiceON.dmg…"
hdiutil create -ov -volname VoiceON -srcfolder "$STAGE" -format UDZO -imagekey zlib-level=9 "$REPO_DIR/dist/VoiceON.dmg"
hdiutil verify "$REPO_DIR/dist/VoiceON.dmg"
(cd "$REPO_DIR/dist" && shasum -a 256 VoiceON.dmg > VoiceON.dmg.sha256)
echo "Готово: $REPO_DIR/dist/VoiceON.dmg"
