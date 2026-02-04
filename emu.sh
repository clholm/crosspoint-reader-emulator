#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../crosspoint-reader"

echo "=== Building emulated firmware ==="
cd "$PROJECT_DIR" && pio run -e emulated

echo ""
echo "=== Creating flash image ==="
"$SCRIPT_DIR/build_flash_image.sh"

echo ""
echo "=== Launching QEMU ==="
"$SCRIPT_DIR/run_qemu.sh" "${1:-display}"
