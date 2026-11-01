"""Kenney Fantasy Town colormap -> Antalya varyantı: lila sıva beyaz badana, camgöbeği çatı kiremit.
Kullanım: python -I tools/make_antalya_colormap.py <proje_dizini>"""
import colorsys, os, sys
from PIL import Image

root = sys.argv[1]
src = os.path.join(root, "assets/models/town/Textures/colormap.png")
dst = os.path.join(root, "assets/models/town/Textures/colormap_antalya.png")
im = Image.open(src).convert("RGBA")
px = im.load()
for y in range(im.size[1]):
    for x in range(im.size[0]):
        r, g, b, a = px[x, y]
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        hd = h * 360
        if 200 <= hd <= 250 and s < 0.4 and v > 0.25:
            k = min(1.0, v / 0.85)
            nr, ng, nb = 0.97 * k, 0.95 * k, 0.9 * k  # kireç badana
        elif 140 <= hd <= 190 and s > 0.3:
            nr, ng, nb = colorsys.hsv_to_rgb(14 / 360, 0.66, min(1.0, v * 0.98))  # kiremit
        else:
            continue
        px[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
im.save(dst)
print("ok", dst)
