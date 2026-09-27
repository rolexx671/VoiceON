#!/bin/bash
set -euo pipefail

# Локальный запуск синхронных тестов с Command Line Tools, где нет XCTest.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

if [ "$(uname -s)" != 'Darwin' ]; then
    printf '%s\n' 'Локальные проверки требуют macOS и Command Line Tools.' >&2
    exit 1
fi

TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/voiceon-local-tests.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

python3 Tests/Standalone/generate.py "$REPO_DIR" "$TEST_DIR"
printf '%s\n' 'Компиляция исходников VoiceON и локальных проверок…'
xcrun swiftc -swift-version 5 -parse-as-library \
    -module-name VoiceONLocalChecks \
    -framework AppKit -framework AVFoundation -framework CoreAudio \
    -framework AudioToolbox -framework Carbon \
    Sources/OpenWisprLib/*.swift Tests/Standalone/Harness.swift "$TEST_DIR"/*.swift \
    -o "$TEST_DIR/voiceon-local-tests"
"$TEST_DIR/voiceon-local-tests"
