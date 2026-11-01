"""Blender modelcisi için teslim paketi: belgeler + referans modeller + ekran görüntüleri.
Kullanım: python -I tools/make_blender_pack.py <proje_dizini>
Çıktı: build/MuhtarKurakYaz_blender_paketi.zip"""
import os, sys, zipfile

root = sys.argv[1]
out = os.path.join(root, "build", "MuhtarKurakYaz_blender_paketi.zip")
docs = [("docs/blender/README.md", "README.md")]
for f in ["01_binalar.md", "02_doga_ve_arazi.md", "03_karakter_hayvan_arac.md", "04_efektler.md"]:
    docs.append(("docs/blender/" + f, "belgeler/" + f))
docs += [("docs/BLENDER_NAMING.md", "belgeler/BLENDER_NAMING.md"), ("docs/MODELS_3D.md", "belgeler/MODELS_3D.md")]
shots = ["01_menu", "3d_04b_taurus", "3d_04c_sea", "3d_06_buildings", "3d_07_buildings_back", "3d_09_actors",
         "3d_10_villagers", "3d_11_fire_bubble", "3d_12_night", "3d_23_lamp_night", "3d_14_shop", "3d_16_select_card",
         "3d_17_crop_picker", "07_minigame"]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for src, dst in docs:
        z.write(os.path.join(root, src), dst)
    models = os.path.join(root, "assets", "models")
    for dirpath, _, files in os.walk(models):
        for f in files:
            if f.endswith(".import") or f.endswith(".uid"):
                continue
            p = os.path.join(dirpath, f)
            z.write(p, os.path.join("referans_modeller", os.path.relpath(p, models)))
    for s in shots:
        p = os.path.join(root, "tests", "shots", s + ".png")
        if os.path.exists(p):
            z.write(p, "ekran_goruntuleri/" + s + ".png")
print("ok", out, round(os.path.getsize(out) / 1e6, 1), "MB")
