#!/usr/bin/env python3
import os
import re
import shutil
import sys
from pathlib import Path

try:
    from PIL import Image
except Exception:
    Image = None

repo = Path(sys.argv[1]).resolve()
builder = Path(sys.argv[2]).resolve()
app_dir = repo / "clients" / "android" / "app"
if not app_dir.exists():
    raise SystemExit(f"Android app not found: {app_dir}")

APP_NAME = "TurovTun"
APP_ID = "com.turov.turovtun"

# 1) Gradle: unique install package + APK file name.
for gradle in [app_dir / "build.gradle.kts", app_dir / "build.gradle"]:
    if gradle.exists():
        s = gradle.read_text(encoding="utf-8")
        s = re.sub(r'applicationId\s*=\s*"[^"]+"', f'applicationId = "{APP_ID}"', s)
        s = re.sub(r'base\.archivesName\.set\("[^"]+"\)', 'base.archivesName.set("TurovTun-${versionName}")', s)
        s = s.replace('base.archivesName.set("SFA-${versionName}")', 'base.archivesName.set("TurovTun-${versionName}")')
        gradle.write_text(s, encoding="utf-8")

# 2) Strings and visible labels.
res_dir = app_dir / "src" / "main" / "res"
if res_dir.exists():
    for p in res_dir.rglob("*.xml"):
        try:
            s = p.read_text(encoding="utf-8")
        except Exception:
            continue
        orig = s
        s = s.replace("sing-box for Android", APP_NAME)
        s = s.replace("Sing-box for Android", APP_NAME)
        s = s.replace("sing-box", APP_NAME)
        s = s.replace("SFA", APP_NAME)
        # Keep config protocol/package internals intact; this targets only resources.
        if s != orig:
            p.write_text(s, encoding="utf-8")

# 3) Add/override app name resource if possible.
values = res_dir / "values"
values.mkdir(parents=True, exist_ok=True)
strings = values / "strings.xml"
if strings.exists():
    s = strings.read_text(encoding="utf-8")
    if 'name="app_name"' in s:
        s = re.sub(r'<string name="app_name">.*?</string>', f'<string name="app_name">{APP_NAME}</string>', s)
    else:
        s = s.replace("</resources>", f'    <string name="app_name">{APP_NAME}</string>\n</resources>')
    strings.write_text(s, encoding="utf-8")
else:
    strings.write_text(f'<resources>\n    <string name="app_name">{APP_NAME}</string>\n</resources>\n', encoding="utf-8")

# 4) Icons.
icon_src = builder / "branding" / "turovtun_icon.png"
if icon_src.exists() and Image is not None:
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    img = Image.open(icon_src).convert("RGBA")
    for folder, size in densities.items():
        d = res_dir / folder
        d.mkdir(parents=True, exist_ok=True)
        resized = img.resize((size, size), Image.LANCZOS)
        for name in ["ic_launcher.png", "ic_launcher_round.png", "ic_launcher_foreground.png"]:
            resized.save(d / name)
    # If adaptive icons reference foreground/background, add simple XML background color.
    drawable = res_dir / "drawable"
    drawable.mkdir(parents=True, exist_ok=True)
    (drawable / "ic_launcher_background.xml").write_text('''<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">\n    <solid android:color="#050505"/>\n</shape>\n''', encoding="utf-8")

# 5) Include TurovTun web UI assets for future/custom screens and for license transparency.
assets_dir = app_dir / "src" / "main" / "assets" / "turovtun"
assets_dir.mkdir(parents=True, exist_ok=True)
for src_name, dst_name in [
    ("branding/turovtun_icon.png", "icon.png"),
    ("branding/map_darktheme.svg", "map_darktheme.svg"),
    ("docs/pc_preview.png", "pc_preview.png"),
]:
    src = builder / src_name
    if src.exists():
        shutil.copy2(src, assets_dir / dst_name)

# 6) Manifest label/icon fallback.
manifest = app_dir / "src" / "main" / "AndroidManifest.xml"
if manifest.exists():
    s = manifest.read_text(encoding="utf-8")
    if "android:label" in s:
        s = re.sub(r'android:label="[^"]+"', 'android:label="@string/app_name"', s, count=1)
    s = re.sub(r'android:icon="[^"]+"', 'android:icon="@mipmap/ic_launcher"', s, count=1)
    s = re.sub(r'android:roundIcon="[^"]+"', 'android:roundIcon="@mipmap/ic_launcher_round"', s, count=1)
    manifest.write_text(s, encoding="utf-8")

# 7) Add a small marker file so build logs prove patch ran.
(app_dir / "src" / "main" / "assets" / "turovtun" / "README.txt").write_text(
    "TurovTun branding/assets injected by scripts/patch_sfa.py. The VPN engine is official sing-box/libbox Android core.\n",
    encoding="utf-8",
)
print("TurovTun patch applied")
