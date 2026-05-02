#!/usr/bin/env python3
import os
import re
import sys
from pathlib import Path

root = Path(sys.argv[1] if len(sys.argv) > 1 else "upstream-sing-box")
if not root.exists():
    raise SystemExit(f"Root not found: {root}")

APP_NAME = "TurovTun"
APP_ID = "com.turov.turovtun"

text_ext = {".xml", ".gradle", ".kts", ".kt", ".java", ".properties"}

# 1) Patch app label strings.
for p in root.rglob("strings.xml"):
    s = p.read_text(errors="ignore")
    original = s
    s = re.sub(r'(<string\s+name="app_name"[^>]*>)(.*?)(</string>)', rf'\1{APP_NAME}\3', s, flags=re.S)
    s = re.sub(r'(<string\s+name="application_name"[^>]*>)(.*?)(</string>)', rf'\1{APP_NAME}\3', s, flags=re.S)
    s = s.replace('>sing-box<', f'>{APP_NAME}<')
    if s != original:
        p.write_text(s)
        print(f"patched strings: {p}")

# 2) Patch applicationId only. Keep namespace/R package to reduce breakage.
for p in list(root.rglob("build.gradle")) + list(root.rglob("build.gradle.kts")):
    s = p.read_text(errors="ignore")
    original = s
    s = re.sub(r'(applicationId\s*[= ]\s*["\'])io\.nekohasekai\.sfa(["\'])', rf'\1{APP_ID}\2', s)
    s = re.sub(r'(applicationId\s*[= ]\s*["\'])io\.nekohasekai\.sfa\.debug(["\'])', rf'\1{APP_ID}.debug\2', s)
    # optional: version name suffix for clarity
    if s != original:
        p.write_text(s)
        print(f"patched gradle appId: {p}")

# 3) Add simple TurovTun vector icon and try to point manifest to it.
res_dirs = list(root.glob("clients/android/app/src/main/res"))
for res in res_dirs:
    drawable = res / "drawable"
    drawable.mkdir(parents=True, exist_ok=True)
    (drawable / "ic_turovtun.xml").write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#050505" android:pathData="M0,0h108v108h-108z"/>
    <path android:strokeColor="#FFFFFF" android:strokeWidth="4" android:fillColor="#00000000" android:pathData="M54,14 L82,26 L77,72 C74,88 62,98 54,101 C46,98 34,88 31,72 L26,26 Z"/>
    <path android:fillColor="#FFFFFF" android:pathData="M35,32h38v9h-14v39h-10v-39h-14z"/>
</vector>\n''')
    print(f"added icon: {drawable / 'ic_turovtun.xml'}")

for manifest in root.rglob("AndroidManifest.xml"):
    s = manifest.read_text(errors="ignore")
    original = s
    if "android:icon=" in s:
        s = re.sub(r'android:icon="@[^"]+"', 'android:icon="@drawable/ic_turovtun"', s, count=1)
    if "android:roundIcon=" in s:
        s = re.sub(r'android:roundIcon="@[^"]+"', 'android:roundIcon="@drawable/ic_turovtun"', s, count=1)
    if s != original:
        manifest.write_text(s)
        print(f"patched manifest icon: {manifest}")

print("Branding patch completed.")
