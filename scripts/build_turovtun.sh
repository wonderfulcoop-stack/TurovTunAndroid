#!/usr/bin/env bash
set -euo pipefail

echo "==> Start TurovTun REAL build"

ROOT_DIR="$(pwd)"
WORK_DIR="$ROOT_DIR/work"
OUT_DIR="$ROOT_DIR/output"

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$OUT_DIR"

cd "$WORK_DIR"

echo "==> Clone Android client"
git clone --depth 1 https://github.com/SagerNet/sing-box-for-android.git
cd sing-box-for-android

echo "==> Download libbox.aar (fixed version)"
mkdir -p app/libs

# ЖЁСТКО ЗАФИКСИРОВАННАЯ РАБОЧАЯ ВЕРСИЯ
LIBBOX_URL="https://github.com/SagerNet/sing-box/releases/download/v1.8.0/libbox.aar"

curl -fL --retry 5 --retry-delay 5 -o app/libs/libbox.aar "$LIBBOX_URL"

if [ ! -s app/libs/libbox.aar ]; then
  echo "ERROR: libbox.aar not downloaded"
  exit 1
fi

echo "==> Apply branding"
if [ -f "$ROOT_DIR/scripts/patch_sfa.py" ]; then
  python3 "$ROOT_DIR/scripts/patch_sfa.py" "$PWD" "$ROOT_DIR" || true
fi

echo "==> Build APK"
chmod +x ./gradlew || true

./gradlew --no-daemon :app:assembleOtherDebug || \
./gradlew --no-daemon :app:assembleDebug

echo "==> Collect APK"
find app/build/outputs/apk -type f -name "*.apk" -print -exec cp -f {} "$OUT_DIR/" \;

echo "==> Done"
ls -la "$OUT_DIR"
