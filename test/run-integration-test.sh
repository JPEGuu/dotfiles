#!/bin/bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_NAME="dotfiles-integration-test"
LOG=$(mktemp)

echo "🐳 Building Docker integration test image..."
echo "This might take a while as it installs all packages (including Node.js and Rust tools)..."

if docker build \
    --progress=plain \
    -f "$DOTFILES_DIR/test/Dockerfile.integration-test" \
    -t "$IMAGE_NAME" \
    "$DOTFILES_DIR" \
    2>&1 | tee "$LOG"; then
    echo ""
    echo "✅ Integration test passed!"
    grep "PASS:" "$LOG" || true
else
    echo ""
    echo "❌ Integration test failed. Check the output above."
    rm -f "$LOG"
    exit 1
fi

rm -f "$LOG"
