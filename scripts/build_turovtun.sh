#!/usr/bin/env bash
set -euo pipefail

echo "==> TurovTun FINAL build (stable)"

ROOT_DIR="$(pwd)"
WORK_DIR="$ROOT_DIR/work"
OUT_DIR="$ROOT_DIR/output"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$OUT_DIR"

cd "$WORK_DIR"

echo "==> Download ready SFA APK"

curl -L -o base.apk \
https://github.com/SagerNet/sing-box-for-android/releases/latest/download/app-universal-debug.apk

if [ ! -s base.apk ]; then
  echo "ERROR: APK not downloaded"
  exit 1
fi

echo "==> Rename to TurovTun.apk"
cp base.apk "$OUT_DIR/TurovTun.apk"

echo "==> Done"
ls -la "$OUT_DIR"
