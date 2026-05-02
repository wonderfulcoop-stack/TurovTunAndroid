#!/usr/bin/env bash
set -euo pipefail

echo "==> TurovTun FINAL APK download"

ROOT_DIR="$(pwd)"
OUT_DIR="$ROOT_DIR/output"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

APK_URL="https://sourceforge.net/projects/sing-box.mirror/files/v1.12.20/SFA-1.12.20-foss-universal.apk/download"

echo "==> Download real SFA APK"
curl -fL --retry 5 --retry-delay 5 -A "Mozilla/5.0" -o "$OUT_DIR/TurovTun.apk" "$APK_URL"

SIZE="$(stat -c%s "$OUT_DIR/TurovTun.apk")"
echo "APK size: $SIZE bytes"

if [ "$SIZE" -lt 10000000 ]; then
  echo "ERROR: downloaded file is too small, not a real APK"
  exit 1
fi

echo "==> Done"
ls -lh "$OUT_DIR"
