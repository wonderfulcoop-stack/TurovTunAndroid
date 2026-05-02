#!/usr/bin/env bash
set -euo pipefail

echo "==> Start TurovTun REAL build"

ROOT_DIR="$(pwd)"
WORK_DIR="$ROOT_DIR/work"
OUT_DIR="$ROOT_DIR/output"

mkdir -p "$WORK_DIR" "$OUT_DIR"
cd "$WORK_DIR"

echo "==> Clone sing-box core"
git clone --depth 1 https://github.com/SagerNet/sing-box.git sing-box-core

echo "==> Build libbox.aar"
cd sing-box-core

export ANDROID_NDK_HOME="$ANDROID_HOME/ndk/27.2.12479018"
export NDK="$ANDROID_NDK_HOME"
export PATH="$ANDROID_NDK_HOME:$PATH"

make lib_install
make lib_android

echo "==> Clone sing-box Android client"
cd "$WORK_DIR"
git clone --depth 1 https://github.com/SagerNet/sing-box-for-android.git sing-box-for-android

echo "==> Copy libbox.aar into Android app"
mkdir -p "$WORK_DIR/sing-box-for-android/app/libs"

if [ -f "$WORK_DIR/sing-box-core/libbox.aar" ]; then
  cp "$WORK_DIR/sing-box-core/libbox.aar" "$WORK_DIR/sing-box-for-android/app/libs/libbox.aar"
elif [ -f "$WORK_DIR/sing-box-core/bin/libbox.aar" ]; then
  cp "$WORK_DIR/sing-box-core/bin/libbox.aar" "$WORK_DIR/sing-box-for-android/app/libs/libbox.aar"
else
  echo "ERROR: libbox.aar not found"
  find "$WORK_DIR/sing-box-core" -name "*libbox*.aar" -o -name "libbox.aar"
  exit 1
fi

echo "==> Apply TurovTun branding"
cd "$WORK_DIR/sing-box-for-android"
if [ -f "$ROOT_DIR/scripts/patch_sfa.py" ]; then
  python3 "$ROOT_DIR/scripts/patch_sfa.py" "$PWD" "$ROOT_DIR" || true
fi

echo "==> Build Android APK"
chmod +x ./gradlew || true
./gradlew --no-daemon :app:assembleDebug

echo "==> Collect APK"
find app/build/outputs/apk -type f -name "*.apk" -print -exec cp -f {} "$OUT_DIR/" \;

echo "==> Done"
ls -la "$OUT_DIR"
