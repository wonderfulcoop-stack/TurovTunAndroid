#!/usr/bin/env bash
set -euo pipefail

echo "==> Start TurovTun REAL build"

ROOT_DIR="$(pwd)"
WORK_DIR="$ROOT_DIR/work"
OUT_DIR="$ROOT_DIR/output"

ANDROID_REPO="https://github.com/SagerNet/sing-box-for-android.git"
LIBBOX_URL="https://github.com/SagerNet/sing-box/releases/latest/download/libbox.aar"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$OUT_DIR"

cd "$WORK_DIR"

echo "==> Clone Android client"
git clone --depth 1 "$ANDROID_REPO" sing-box-for-android

cd sing-box-for-android

echo "==> Prepare libbox.aar"
mkdir -p app/libs

echo "==> Download ready libbox.aar"
curl -fL --retry 5 --retry-delay 5 -o app/libs/libbox.aar "$LIBBOX_URL"

if [ ! -s app/libs/libbox.aar ]; then
  echo "ERROR: libbox.aar was not downloaded or file is empty"
  exit 1
fi

echo "==> Apply TurovTun branding"
if [ -f "$ROOT_DIR/scripts/patch_sfa.py" ]; then
  python3 "$ROOT_DIR/scripts/patch_sfa.py" "$PWD" "$ROOT_DIR" || true
else
  echo "WARN: patch_sfa.py not found, skipping branding"
fi

echo "==> Build APK"
chmod +x ./gradlew || true
./gradlew --no-daemon :app:assembleOtherDebug || ./gradlew --no-daemon :app:assembleDebug

echo "==> Collect APK"
mkdir -p "$OUT_DIR"
find app/build/outputs/apk -type f -name "*.apk" -print -exec cp -f {} "$OUT_DIR/" \;

APK_COUNT="$(find "$OUT_DIR" -type f -name "*.apk" | wc -l | tr -d ' ')"

if [ "$APK_COUNT" = "0" ]; then
  echo "ERROR: APK was not created"
  find app/build/outputs -type f || true
  exit 1
fi

echo "==> Done. APK files:"
ls -lh "$OUT_DIR"
