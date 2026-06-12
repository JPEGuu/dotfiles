#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="dotfiles-install-test"
LOG=$(mktemp)

echo "🐳 Building Docker test image..."
if docker build \
    --progress=plain \
    -f "$DOTFILES_DIR/test/Dockerfile.install-test" \
    -t "$IMAGE_NAME" \
    "$DOTFILES_DIR" \
    >"$LOG" 2>&1; then
    grep "PASS:" "$LOG" | sed 's/^#[0-9]* [0-9.]* //'
    echo "✅ All install tests passed."
else
    cat "$LOG"
    rm -f "$LOG"
    exit 1
fi
rm -f "$LOG"
