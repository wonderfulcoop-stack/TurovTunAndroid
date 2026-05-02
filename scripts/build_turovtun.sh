#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORK_DIR="$ROOT_DIR/.build"
OUT_DIR="$ROOT_DIR/output"

SING_BOX_REPO="${SING_BOX_REPO:-https://github.com/SagerNet/sing-box-for-android.git}"
SING_BOX_REF="${SING_BOX_REF:-dev}"

rm -rf "$WORK_DIR" "$OUT_DIR"
mkdir -p "$WORK_DIR" "$OUT_DIR"
cd "$WORK_DIR"

echo "==> Clone sing-box source with Android client"
git clone --recursive --depth=1 --branch "$SING_BOX_REF" "$SING_BOX_REPO" sing-box || {
  echo "Branch '$SING_BOX_REF' not found, trying main..."
  git clone --recursive --depth=1 --branch main "$SING_BOX_REPO" sing-box
}
cd sing-box

ANDROID_APP_DIR="app"
ANDROID_ROOT_DIR="."
if [ ! -d "$ANDROID_APP_DIR" ]; then
  echo "ERROR: app directory not found in sing-box-for-android source"
  echo "Repository layout changed. Send the GitHub Actions log to ChatGPT."
  exit 10
fi

echo "==> Install NDK required by Android project"
NDK_VERSION=""
if [ -f "$ANDROID_APP_DIR/build.gradle.kts" ]; then
  NDK_VERSION=$(grep -oE 'ndkVersion = "[0-9.]+' "$ANDROID_APP_DIR/build.gradle.kts" | head -1 | sed 's/ndkVersion = "//') || true
fi
if [ -z "$NDK_VERSION" ] && [ -f "$ANDROID_APP_DIR/build.gradle" ]; then
  NDK_VERSION=$(grep -oE 'ndkVersion "[0-9.]+' "$ANDROID_APP_DIR/build.gradle" | head -1 | sed 's/ndkVersion "//') || true
fi
if [ -n "$NDK_VERSION" ]; then
  sdkmanager "ndk;$NDK_VERSION" || true
fi

echo "==> Build libbox core for Android"
make lib_install
make lib_android
mkdir -p "$ANDROID_APP_DIR/libs"
if [ -f libbox.aar ]; then
  mv -f libbox.aar "$ANDROID_APP_DIR/libs/libbox.aar"
elif [ -f bin/libbox.aar ]; then
  mv -f bin/libbox.aar "$ANDROID_APP_DIR/libs/libbox.aar"
else
  echo "ERROR: libbox.aar not created"
  find . -name 'libbox*.aar' -maxdepth 5 || true
  exit 11
fi
# Some variants expect legacy aar too. Use the same core if legacy was not produced.
cp -f "$ANDROID_APP_DIR/libs/libbox.aar" "$ANDROID_APP_DIR/libs/libbox-legacy.aar" || true

echo "==> Apply TurovTun branding and Android tweaks"
python3 "$ROOT_DIR/scripts/patch_sfa.py" "$PWD" "$ROOT_DIR"

echo "==> Build Android APK"
cd "$ANDROID_ROOT_DIR"
chmod +x ./gradlew || true
./gradlew --no-daemon :app:assembleDebug

echo "==> Collect APK files"
find app/build/outputs/apk -type f -name '*.apk' -print -exec cp -f {} "$OUT_DIR/" \;
ls -lh "$OUT_DIR"
