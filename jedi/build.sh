#!/usr/bin/env bash
# Builds the Jedi firmware in Docker (avr-gcc 5.4, Arduino 1.0.5 from Ubuntu 18.04).
# Output: jedi/out/MarlinJedi-<git-describe>.hex
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
docker build -q -t jedi-fw-builder "$ROOT/jedi" >/dev/null
docker run --rm -u "$(id -u):$(id -g)" -v "$ROOT:/src" jedi-fw-builder \
  bash -c "make -s clean >/dev/null; make -s HARDWARE_MOTHERBOARD=72 AVR_TOOLS_PATH= 2>&1 | grep -E 'rror|Program|Data:'"
mkdir -p "$ROOT/jedi/out"
OUT="$ROOT/jedi/out/MarlinJedi-$(git -C "$ROOT" describe --always --dirty --tags).hex"
cp "$ROOT/Marlin/applet/Marlin.hex" "$OUT"
echo "$OUT"
