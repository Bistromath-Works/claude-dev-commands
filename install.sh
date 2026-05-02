#!/usr/bin/env bash
set -e

DEST="$HOME/.claude/commands"
mkdir -p "$DEST"

cp "$(dirname "$0")/dev-scope.md" "$DEST/dev-scope.md"
cp "$(dirname "$0")/dev-ship.md"  "$DEST/dev-ship.md"
cp "$(dirname "$0")/dev-go.md"    "$DEST/dev-go.md"

echo "Installed /dev-scope, /dev-ship, and /dev-go to $DEST"
