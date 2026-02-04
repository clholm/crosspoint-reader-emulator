#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../crosspoint-reader"
BUILD_DIR="$PROJECT_DIR/.pio/build/emulated"
OUTPUT="$SCRIPT_DIR/flash_image.bin"

# Find esptool.py from PlatformIO
ESPTOOL=$(find ~/.platformio -name "esptool.py" -type f 2>/dev/null | head -1)
if [ -z "$ESPTOOL" ]; then
  # Fallback: try esptool on PATH
  if command -v esptool.py &>/dev/null; then
    ESPTOOL="esptool.py"
  else
    echo "Error: esptool.py not found. Install with: pip install esptool"
    exit 1
  fi
fi

# Locate build artifacts
BOOTLOADER="$BUILD_DIR/bootloader.bin"
PARTITIONS="$BUILD_DIR/partitions.bin"
FIRMWARE="$BUILD_DIR/firmware.bin"

# Verify files exist
for f in "$BOOTLOADER" "$PARTITIONS" "$FIRMWARE"; do
  if [ ! -f "$f" ]; then
    echo "Error: $(basename "$f") not found at $f"
    echo "Run 'pio run -e emulated' in $PROJECT_DIR first."
    exit 1
  fi
done

# Use PlatformIO's Python virtualenv (has pyserial installed)
PIO_PYTHON="$HOME/.platformio/penv/bin/python3"
if [ ! -e "$PIO_PYTHON" ]; then
  PIO_PYTHON="python3"
fi

echo "Creating merged flash image..."
"$PIO_PYTHON" "$ESPTOOL" --chip esp32c3 merge_bin \
  --output "$OUTPUT" \
  --fill-flash-size 16MB \
  --flash_mode dio \
  --flash_size 16MB \
  0x0 "$BOOTLOADER" \
  0x8000 "$PARTITIONS" \
  0x10000 "$FIRMWARE"

echo "Flash image created: $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
