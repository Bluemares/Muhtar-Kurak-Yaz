"""Builds icon.png (256) and splash.png from the Kenney atlases. Usage: python -I tools/make_icon.py <project_dir>"""
import os, sys
from PIL import Image, ImageDraw

root = sys.argv[1]
town = Image.open(os.path.join(root, "_downloads/kenney_tiny-town/Tilemap/tilemap_packed.png")).convert("RGBA")
farm = Image.open(os.path.join(root, "_downloads/kenney_tiny-farm/Tilemap/tilemap_packed.png")).convert("RGBA")


def tile(sheet, idx, px):
    x, y = (idx % 12) * 16, (idx // 12) * 16
    return sheet.crop((x, y, x + 16, y + 16)).resize((px, px), Image.NEAREST)


def scene(w, h):
    im = Image.new("RGBA", (w, h))
    d = ImageDraw.Draw(im)
    for y in range(h):
        t = y / h
        c = tuple(int(a + (b - a) * t) for a, b in zip((217, 96, 59), (246, 213, 142)))
        d.line([(0, y), (w, y)], fill=c + (255,))
    s = w // 4
    d.ellipse([w - s * 1.6, s * 0.3, w - s * 0.4, s * 1.5], fill=(255, 241, 184, 255))
    gy = int(h * 0.68)
    d.rectangle([0, gy, w, h], fill=(176, 150, 70, 255))
    t = w // 4
    for i, idx in enumerate([52, 54]):
        im.alpha_composite(tile(town, idx, t), (int(w * 0.12) + i * t, gy - 2 * t + t // 4))
    for i, idx in enumerate([84, 87]):
        im.alpha_composite(tile(town, idx, t), (int(w * 0.12) + i * t, gy - t + t // 4))
    for i in range(2):
        im.alpha_composite(tile(farm, 66 if i == 0 else 67, t), (int(w * 0.58) + i * int(t * 0.8), gy - t // 2))
    return im


icon = scene(256, 256)
mask = Image.new("L", (256, 256), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, 255, 255], radius=48, fill=255)
icon.putalpha(mask)
icon.save(os.path.join(root, "icon.png"))
print("ok")
