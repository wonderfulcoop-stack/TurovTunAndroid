#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-upstream-sing-box}"
cd "$ROOT"

echo "== TurovTun real build =="
echo "Repo: $(pwd)"

# Install Android platform / build tools / NDK. Upstream build.gradle usually declares ndkVersion.
ANDROID_APP_DIR="clients/android/app"
ANDROID_DIR="clients/android"

if [ ! -d "$ANDROID_APP_DIR" ]; then
  echo "ERROR: $ANDROID_APP_DIR not found. Upstream layout changed."
  find . -maxdepth 3 -type d | sort | head -200
  exit 1
fi

NDK_VERSION=""
if [ -f "$ANDROID_APP_DIR/build.gradle" ]; then
  NDK_VERSION=$(sed -n -E 's/.*ndkVersion[ =]+["'"'']([^"'"'']+)["'"''].*/\1/p' "$ANDROID_APP_DIR/build.gradle" | head -1 || true)
fi
if [ -f "$ANDROID_APP_DIR/build.gradle.kts" ]; then
  NDK_VERSION=$(sed -n -E 's/.*ndkVersion[ =]+["'"'']([^"'"'']+)["'"''].*/\1/p' "$ANDROID_APP_DIR/build.gradle.kts" | head -1 || true)
fi

sdkmanager "platforms;android-35" "platforms;android-34" "build-tools;35.0.0" "build-tools;34.0.0" "cmdline-tools;latest" >/dev/null
if [ -n "$NDK_VERSION" ]; then
  echo "Installing NDK $NDK_VERSION"
  sdkmanager "ndk;$NDK_VERSION" >/dev/null
else
  echo "NDK version not detected, installing r28.0.13004108 fallback"
  sdkmanager "ndk;28.0.13004108" >/dev/null || true
fi

mkdir -p "$ANDROID_APP_DIR/libs"

# Build libbox.aar exactly like F-Droid/SFA builds do.
echo "Building libbox.aar..."
make lib_install
make lib_android

if [ ! -f libbox.aar ]; then
  echo "ERROR: libbox.aar was not produced."
  find . -maxdepth 3 -name 'libbox*.aar' -print
  exit 1
fi
mv -f libbox.aar "$ANDROID_APP_DIR/libs/libbox.aar"
ls -lah "$ANDROID_APP_DIR/libs/libbox.aar"

# Disable signing checks/debug-only switches if upstream uses them.
find "$ANDROID_DIR" -name 'build.gradle' -o -name 'build.gradle.kts' | while read -r f; do
  sed -i 's/enable[[:space:]]\+true/enable false/g' "$f" || true
  sed -i 's/isEnable[[:space:]]*=[[:space:]]*true/isEnable = false/g' "$f" || true
done

cd "$ANDROID_DIR"
chmod +x ./gradlew || true

# Try known SFA tasks. Upstream task names may differ, so we fall back safely.
set +e
./gradlew --no-daemon :app:assembleOtherRelease
CODE=$?
if [ $CODE -ne 0 ]; then
  echo "assembleOtherRelease failed, trying assembleOtherDebug..."
  ./gradlew --no-daemon :app:assembleOtherDebug
  CODE=$?
fi
if [ $CODE -ne 0 ]; then
  echo "assembleOtherDebug failed, trying assembleRelease..."
  ./gradlew --no-daemon :app:assembleRelease
  CODE=$?
fi
if [ $CODE -ne 0 ]; then
  echo "assembleRelease failed, trying assembleDebug..."
  ./gradlew --no-daemon :app:assembleDebug
  CODE=$?
fi
set -e

if [ $CODE -ne 0 ]; then
  echo "ERROR: All Gradle assemble tasks failed. Available tasks around assemble:"
  ./gradlew --no-daemon tasks --all | grep -i assemble | head -100 || true
  exit $CODE
fi

echo "APK files:"
find . -type f -name '*.apk' -path '*build/outputs/apk*' -print
