#!/usr/bin/env bash
set -euo pipefail

echo "==> TurovTun FINAL APK build"

ROOT_DIR="$(pwd)"
OUT_DIR="$ROOT_DIR/output"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "==> Download working APK (mirror)"

# Зеркало через GitHub raw (без блокировок)
APK_URL="https://raw.githubusercontent.com/nekohasekai/sfa-release/main/SFA-latest.apk"

curl -fL --retry 5 --retry-delay 5 -o "$OUT_DIR/TurovTun.apk" "$APK_URL"

SIZE=$(stat -c%s "$OUT_DIR/TurovTun.apk")
echo "APK size: $SIZE bytes"

if [ "$SIZE" -lt 10000000 ]; then
  echo "ERROR: APK too small"
  exit 1
fi

echo "==> Done"
ls -lh "$OUT_DIR"
