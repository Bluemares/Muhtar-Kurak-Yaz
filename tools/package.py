"""Zips build/web and build/windows for itch.io upload. Usage: python -I tools/package.py <project_dir>"""
import os, sys, zipfile

root = sys.argv[1]
build = os.path.join(root, "build")
for name, src in [("MuhtarKurakYaz_web.zip", "web"), ("MuhtarKurakYaz_windows.zip", "windows")]:
    out = os.path.join(build, name)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        base = os.path.join(build, src)
        for dirpath, _, files in os.walk(base):
            for f in files:
                if f.endswith(".cfg") or f.endswith(".log") or f in ("savegame.json", "profile.json"):
                    continue  # oyuncu ayarlarını pakete koyma
                p = os.path.join(dirpath, f)
                z.write(p, os.path.relpath(p, base))
    print(name, round(os.path.getsize(out) / 1e6, 1), "MB")
