#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLASH_IMAGE="$SCRIPT_DIR/flash_image.bin"

# Find QEMU binary
QEMU_BIN=""
for candidate in \
  "$(find ~/.espressif/tools/qemu-riscv32 -name 'qemu-system-riscv32' -type f 2>/dev/null | head -1)" \
  "$(which qemu-system-riscv32 2>/dev/null || true)"; do
  if [ -n "$candidate" ] && [ -x "$candidate" ]; then
    QEMU_BIN="$candidate"
    break
  fi
done

if [ -z "$QEMU_BIN" ]; then
  echo "Error: qemu-system-riscv32 not found."
  echo ""
  echo "Install Espressif's QEMU fork:"
  echo "  1. brew install libgcrypt glib pixman sdl2 libslirp"
  echo "  2. Download from https://github.com/espressif/qemu/releases"
  echo "     (pick the esp-develop branch, riscv32, macOS arm64 build)"
  echo "  3. Or use idf_tools.py: python3 \$IDF_PATH/tools/idf_tools.py install qemu-riscv32"
  exit 1
fi

if [ ! -f "$FLASH_IMAGE" ]; then
  echo "Error: $FLASH_IMAGE not found. Run build_flash_image.sh first."
  exit 1
fi

MODE="${1:-display}"

echo "Using QEMU: $QEMU_BIN"
echo "Flash image: $FLASH_IMAGE"
echo ""

case "$MODE" in
  display)
    echo "Running with SDL display window..."
    echo "  Button input via serial: h=left j=down k=up l=right c=confirm b=back p=power"
    echo ""
    "$QEMU_BIN" \
      -icount 3 \
      -machine esp32c3 \
      -drive file="$FLASH_IMAGE",if=mtd,format=raw \
      -serial mon:stdio \
      -display sdl
    ;;
  headless)
    echo "Running in headless mode (serial output only)..."
    "$QEMU_BIN" \
      -nographic \
      -icount 3 \
      -machine esp32c3 \
      -drive file="$FLASH_IMAGE",if=mtd,format=raw \
      -serial mon:stdio
    ;;
  gdb)
    echo "Running with GDB server on port 1234 + SDL display..."
    echo "  Connect with: riscv32-esp-elf-gdb .pio/build/emulated/firmware.elf -ex 'target remote :1234'"
    echo ""
    "$QEMU_BIN" \
      -icount 3 \
      -machine esp32c3 \
      -drive file="$FLASH_IMAGE",if=mtd,format=raw \
      -serial mon:stdio \
      -display sdl \
      -s -S
    ;;
  *)
    echo "Usage: $0 [display|headless|gdb]"
    echo ""
    echo "  display   - SDL window + serial (default)"
    echo "  headless  - serial output only"
    echo "  gdb       - SDL window + GDB server on :1234"
    exit 1
    ;;
esac
