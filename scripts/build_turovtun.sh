#!/usr/bin/env bash
set -euo pipefail

echo "==> Start TurovTun REAL build"

ROOT_DIR="$(pwd)"
WORK_DIR="$ROOT_DIR/work"
OUT_DIR="$ROOT_DIR/output"

mkdir -p "$WORK_DIR"
mkdir -p "$OUT_DIR"

cd "$WORK_DIR"

echo "==> Clone sing-box Android client"
git clone https://github.com/SagerNet/sing-box-for-android.git
cd sing-box-for-android

echo "==> Apply TurovTun branding (optional)"
if [ -f "$ROOT_DIR/scripts/patch_sfa.py" ]; then
  python3 "$ROOT_DIR/scripts/patch_sfa.py" "$PWD" "$ROOT_DIR" || true
fi

echo "==> Build Android APK"
chmod +x ./gradlew || true
./gradlew --no-daemon :app:assembleDebug

echo "==> Collect APK"
find app/build/outputs/apk -type f -name '*.apk' -print -exec cp -f {} "$OUT_DIR/" \;

echo "==> Done. APK files:"
ls -la "$OUT_DIR"
