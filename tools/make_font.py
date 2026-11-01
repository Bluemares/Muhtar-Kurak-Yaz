"""Kenney Pixel (CC0) -> BMFont bitmap font with Turkish glyphs composed from existing ones.
Kenney fonts lack g/s/i Turkish letters (ğĞşŞıİ); they are built here by pixel compositing.
Usage: python -I tools/make_font.py <project_dir>
Writes assets/fonts/muhtar_pixel.fnt + muhtar_pixel.png
"""
import os, sys
from PIL import Image, ImageDraw, ImageFont

root = sys.argv[1]
SRC = os.path.join(root, "_downloads/kenney_kenney-fonts/Fonts/Kenney Pixel.ttf")
OUT = os.path.join(root, "assets/fonts")
SIZE = 64
FNT_SIZE = 44  # bildirilen boyut < çizim boyutu: metin aynı font_size ile ~%23 iri görünür
font = ImageFont.truetype(SRC, SIZE)
ASC, DESC = font.getmetrics()
PAD = 4
H = ASC + DESC + PAD * 2


def raw(ch):
    """Glyph as (image L, advance). Image covers the full line height, origin at x=PAD."""
    w = int(font.getlength(ch)) + PAD * 2 + 8
    im = Image.new("L", (max(w, 8), H), 0)
    d = ImageDraw.Draw(im)
    d.fontmode = "1"
    d.text((PAD, PAD + ASC), ch, font=font, fill=255, anchor="ls")
    return im, int(round(font.getlength(ch)))


NOTDEF = bytes(font.getmask("一"))


def exists(ch):
    m = font.getmask(ch)
    return bytes(m) != NOTDEF and m.getbbox() is not None


def unit():
    im, _ = raw("I")
    bb = im.getbbox()
    row = [im.getpixel((x, (bb[1] + bb[3]) // 2)) for x in range(im.width)]
    return max(1, sum(1 for v in row if v))


U = unit()


def diff(a, b):
    """Pixels in glyph a that are not in glyph b (e.g. cedilla = ç - c)."""
    ia, _ = raw(a)
    ib, _ = raw(b)
    out = Image.new("L", ia.size, 0)
    for y in range(ia.height):
        for x in range(ia.width):
            if ia.getpixel((x, y)) and not (x < ib.width and ib.getpixel((x, y))):
                out.putpixel((x, y), 255)
    return out


def paste(base, mark, dx=0, dy=0):
    out = base.copy()
    for y in range(mark.height):
        for x in range(mark.width):
            if mark.getpixel((x, y)):
                xx, yy = x + dx, y + dy
                if 0 <= xx < out.width and 0 <= yy < out.height:
                    out.putpixel((xx, yy), 255)
    return out


def center_x(im):
    bb = im.getbbox()
    return (bb[0] + bb[2]) / 2 if bb else im.width / 2


def pattern(rows, top, cx, w):
    """Draw a pixel pattern (list of strings, 'X' = on) scaled by U, centered at cx, top y."""
    im = Image.new("L", (w, H), 0)
    pw = len(rows[0]) * U
    x0 = int(round(cx - pw / 2))
    for r, line in enumerate(rows):
        for c, ch in enumerate(line):
            if ch == "X":
                for yy in range(U):
                    for xx in range(U):
                        px, py = x0 + c * U + xx, top + r * U + yy
                        if 0 <= px < w and 0 <= py < H:
                            im.putpixel((px, py), 255)
    return im


def top_of(ch):
    im, _ = raw(ch)
    return im.getbbox()[1]


def umlaut_top(upper):
    """Top y of the umlaut dots on Ö / ö: used as height for breve and dot accents."""
    d = diff("Ö" if upper else "ö", "O" if upper else "o")
    return d.getbbox()[1]


def compose(ch):
    if ch in ("ğ", "Ğ"):  # ğ Ğ: g/G + breve
        upper = ch == "Ğ"
        base, adv = raw("G" if upper else "g")
        mark = pattern(["X..X", ".XX."], umlaut_top(upper), center_x(base), base.width)
        return paste(base, mark), adv
    if ch in ("ş", "Ş"):  # ş Ş: s/S + cedilla taken from ç/Ç
        upper = ch == "Ş"
        base, adv = raw("S" if upper else "s")
        ced = diff("Ç" if upper else "ç", "C" if upper else "c")
        cref, _ = raw("C" if upper else "c")
        return paste(base, ced, int(round(center_x(base) - center_x(cref)))), adv
    if ch == "ı":  # ı: i without the dot (drop pixels above x-height)
        base, adv = raw("i")
        xh = top_of("x")
        out = base.copy()
        for y in range(xh):
            for x in range(out.width):
                out.putpixel((x, y), 0)
        return out, adv
    if ch == "İ":  # İ: I + dot
        base, adv = raw("I")
        mark = pattern(["X"], umlaut_top(True), center_x(base), base.width)
        return paste(base, mark), adv
    if ch == "â":  # â: a + circumflex
        base, adv = raw("a")
        mark = pattern([".X.", "X.X"], umlaut_top(False), center_x(base), base.width)
        return paste(base, mark), adv
    if ch == "°":  # °
        base, adv = raw(" ")
        im = Image.new("L", (U * 6 + PAD * 2, H), 0)
        mark = pattern(["XXX", "X.X", "XXX"], top_of("H"), PAD + U * 2, im.width)
        return paste(im, mark), U * 4
    if ch == "·":  # ·
        im = Image.new("L", (U * 4 + PAD * 2, H), 0)
        xh = top_of("x")
        mark = pattern(["X"], (xh + PAD + ASC) // 2 - U // 2, PAD + U * 1.5, im.width)
        return paste(im, mark), U * 3
    if ch == "»":
        return raw(">")
    if ch in ("–", "−"):
        return raw("-")
    if ch == "—":  # — : wide dash
        b, adv = raw("-")
        bb = b.getbbox()
        seg = b.crop((bb[0], bb[1], bb[2], bb[3]))
        w = adv * 2
        im = Image.new("L", (w + PAD * 2, H), 0)
        for x in range(PAD, PAD + w - U, max(1, seg.width - U)):
            im = paste(im, seg, x, bb[1]) if False else im
        d = ImageDraw.Draw(im)
        d.rectangle([PAD, bb[1], PAD + w - U, bb[3] - 1], fill=255)
        return im, w
    if ch == "→":  # → : dash + arrow head
        b, adv = raw(">")
        d_, _ = raw("-")
        bb = d_.getbbox()
        im = Image.new("L", (b.width + adv, H), 0)
        dr = ImageDraw.Draw(im)
        dr.rectangle([PAD, bb[1], PAD + adv, bb[3] - 1], fill=255)
        return paste(im, b, adv - U * 2), adv * 2 - U
    return raw(ch)


chars = [chr(c) for c in range(32, 127)] + list("°·»ÇÖÜâçöüğĞİıŞş–—→−")
glyphs = []
for ch in chars:
    im, adv = raw(ch) if exists(ch) and ch not in "ğĞşŞıİ" else compose(ch)
    bb = im.getbbox()
    if bb is None:
        glyphs.append((ch, None, 0, 0, adv))
        continue
    glyphs.append((ch, im.crop(bb), bb[0] - PAD, bb[1] - PAD, adv))

# atlas
AW = 1024
x = y = 2
row_h = 0
places = []
for g in glyphs:
    if g[1] is None:
        places.append((0, 0))
        continue
    w, h = g[1].size
    if x + w + 2 > AW:
        x = 2
        y += row_h + 2
        row_h = 0
    places.append((x, y))
    x += w + 2
    row_h = max(row_h, h)
AH = 1
while AH < y + row_h + 2:
    AH *= 2
atlas = Image.new("RGBA", (AW, AH), (255, 255, 255, 0))
lines = []
for g, (px, py) in zip(glyphs, places):
    ch, im, xo, yo, adv = g
    if im is not None:
        white = Image.new("RGBA", im.size, (255, 255, 255, 255))
        atlas.paste(white, (px, py), im)
        w, h = im.size
    else:
        w = h = 0
    lines.append(f"char id={ord(ch)} x={px} y={py} width={w} height={h} xoffset={xo} yoffset={yo} xadvance={adv} page=0 chnl=15")

os.makedirs(OUT, exist_ok=True)
atlas.save(os.path.join(OUT, "muhtar_pixel.png"))
with open(os.path.join(OUT, "muhtar_pixel.fnt"), "w", encoding="utf-8", newline="\n") as f:
    f.write(f'info face="MuhtarPixel" size={FNT_SIZE} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=2,2\n')
    f.write(f"common lineHeight={ASC + DESC + U * 2} base={ASC} scaleW={AW} scaleH={AH} pages=1 packed=0\n")
    f.write('page id=0 file="muhtar_pixel.png"\n')
    f.write(f"chars count={len(lines)}\n")
    f.write("\n".join(lines) + "\n")
print("ok glyphs", len(lines), "unit", U, "atlas", AW, AH)
