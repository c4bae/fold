#!/bin/bash
# Builds Fold.app into ./build and signs it with the stable dev identity.
# Usage: scripts/build.sh [--debug] [--run]
set -euo pipefail
trap 'echo "error: ${BASH_SOURCE[0]} failed at line $LINENO" >&2' ERR

cd "$(dirname "$0")/.."

CONFIG=release
RUN=0
for arg in "$@"; do
    case "$arg" in
        --debug) CONFIG=debug ;;
        --run) RUN=1 ;;
        *) echo "Unknown option: $arg" >&2; exit 1 ;;
    esac
done

IDENTITY="Fold Dev"
APP="build/Fold.app"

swift build -c "$CONFIG"
BIN="$(swift build -c "$CONFIG" --show-bin-path)/Fold"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Fold"
cp Resources/Info.plist "$APP/Contents/Info.plist"

if [[ "$(security find-identity -p codesigning)" != *"\"$IDENTITY\""* ]]; then
    echo "Signing identity \"$IDENTITY\" not found. Run scripts/create-dev-cert.sh first." >&2
    exit 1
fi
codesign --force --options runtime --timestamp=none -s "$IDENTITY" "$APP"

echo "Built $APP"

if [ "$RUN" = 1 ]; then
    pkill -x Fold 2>/dev/null || true
    # `open` fails if the old instance is still shutting down.
    for _ in $(seq 50); do
        pgrep -x Fold >/dev/null || break
        sleep 0.1
    done
    open "$APP"
fi
