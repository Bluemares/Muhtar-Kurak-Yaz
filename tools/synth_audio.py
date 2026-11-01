"""Procedural loops and theme music for MUHTAR: KURAK YAZ (stdlib only).
Usage: python -I tools/synth_audio.py <project_dir>
Writes assets/audio/sfx/{hose,crackle,siren,sizzle,cicada}.wav and assets/audio/music/theme.wav
Only one clip: python -I tools/synth_audio.py <project_dir> cicada
"""
import math, random, struct, sys, wave, os

SR = 22050
random.seed(31)


def write(path, data, vol=0.9):
    peak = max(1e-6, max(abs(x) for x in data))
    k = vol / peak
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x * k)) * 32767)) for x in data))


def loopify(data, fade):
    """Crossfade the tail into the head so the clip loops seamlessly."""
    n = int(fade * SR)
    body = data[:-n]
    for i in range(n):
        t = i / n
        body[i] = body[i] * t + data[len(data) - n + i] * (1 - t)
    return body


def noise(n):
    return [random.uniform(-1, 1) for _ in range(n)]


def lowpass(d, a):
    y, out = 0.0, []
    for x in d:
        y += a * (x - y)
        out.append(y)
    return out


def highpass(d, a):
    lp = lowpass(d, a)
    return [x - l for x, l in zip(d, lp)]


def hose():
    d = highpass(lowpass(noise(int(1.7 * SR)), 0.35), 0.02)
    d = [x * (0.85 + 0.15 * math.sin(i / SR * 2 * math.pi * 7)) for i, x in enumerate(d)]
    return loopify(d, 0.2)


def crackle():
    n = int(3.2 * SR)
    d = [x * 0.5 for x in lowpass(noise(n), 0.015)]
    for _ in range(90):
        p = random.randrange(n - 800)
        ln = random.randint(60, 600)
        amp = random.uniform(0.2, 1.0)
        for i in range(ln):
            d[p + i] += random.uniform(-1, 1) * amp * math.exp(-i / (ln * 0.25))
    return loopify(d, 0.2)


def siren():
    n = int(2.4 * SR)
    d, ph = [], 0.0
    for i in range(n):
        t = i / SR
        f = 950 if (t % 1.2) < 0.6 else 760
        ph += 2 * math.pi * f / SR
        d.append(math.sin(ph) + 0.25 * math.sin(3 * ph) + 0.1 * math.sin(5 * ph))
    return loopify(d, 0.1)


def sizzle():
    n = int(0.45 * SR)
    d = highpass(noise(n), 0.3)
    return [x * math.exp(-i / (n * 0.3)) * min(1, i / 200) for i, x in enumerate(d)]


# ---------------- music ----------------
BPM = 100
E = 60.0 / BPM / 2  # eighth note seconds
D4 = 293.66


def pluck(freq, dur, bright=0.5):
    """Karplus-Strong plucked string (saz-like)."""
    n = int(dur * SR)
    p = max(2, int(SR / freq))
    buf = [random.uniform(-1, 1) for _ in range(p)]
    out = []
    for i in range(n):
        v = buf[i % p]
        nxt = buf[(i + 1) % p]
        buf[i % p] = (v * bright + nxt * (1 - bright)) * 0.996
        out.append(v)
    return out


def add(dst, src, at, gain):
    for i, x in enumerate(src):
        j = at + i
        if j >= len(dst):
            break
        dst[j] += x * gain


def drum(low):
    n = int(0.25 * SR)
    out, ph = [], 0.0
    for i in range(n):
        t = i / SR
        if low:
            f = 55 + 70 * math.exp(-t * 30)
            ph += 2 * math.pi * f / SR
            out.append(math.sin(ph) * math.exp(-t * 14))
        else:
            out.append(random.uniform(-1, 1) * math.exp(-t * 60) * 0.6 + math.sin(2 * math.pi * 420 * t) * math.exp(-t * 40) * 0.4)
    return out


# Hicaz on D; numbers are semitones above D4, None = rest, '-' = hold previous
PHRASES = [
    [7, '-', 8, 7, 5, 4, '-', 5, 4, 1, 0, '-', '-', '-', None, None],
    [0, 1, 4, 5, 7, '-', 5, 4, 5, 4, 1, 4, 0, '-', '-', None],
    [7, 8, 10, 12, 10, '-', 8, 7, 8, 7, 5, 4, 5, '-', '-', None],
    [4, 5, 7, 5, 4, 1, '-', 0, 1, '-', 0, '-', '-', '-', None, None],
]
RHYTHM = ['D', 'T', None, 'T', 'D', None, 'T', None]


def theme():
    melody = PHRASES + [PHRASES[0], PHRASES[1], [p if not isinstance(p, int) else (p + 12 if p < 5 else p) for p in PHRASES[2]], PHRASES[3]]
    steps = sum(len(p) for p in melody)
    n = int(steps * E * SR)
    out = [0.0] * n
    # drone (D + A), slow swell
    for i in range(n):
        t = i / SR
        sw = 0.6 + 0.4 * math.sin(2 * math.pi * t / 9.6)
        out[i] += (math.sin(2 * math.pi * D4 / 2 * t) * 0.5 + math.sin(2 * math.pi * D4 * 0.75 * t) * 0.25) * 0.12 * sw
    # melody
    seq = [s for p in melody for s in p]
    i = 0
    while i < len(seq):
        s = seq[i]
        ln = 1
        while i + ln < len(seq) and seq[i + ln] == '-':
            ln += 1
        if isinstance(s, int):
            f = D4 * 2 ** (s / 12)
            note = pluck(f, ln * E + 0.6, 0.55)
            add(out, note, int(i * E * SR), 0.5)
            add(out, pluck(f * 1.003, ln * E + 0.4, 0.6), int(i * E * SR) + 90, 0.18)
        i += ln
    # darbuka
    for k in range(steps):
        r = RHYTHM[k % 8]
        if r:
            add(out, drum(r == 'D'), int(k * E * SR), 0.35 if r == 'D' else 0.18)
    f = int(0.02 * SR)
    for k in range(f):
        out[k] *= k / f
        out[-1 - k] *= k / f
    return out


def cicada():
    """Ağustos böceği korosu: ~4.4 kHz cızırtı, 50 Hz titreşim, yavaş yükselip alçalan dalgalar."""
    n = int(8.0 * SR)
    rnd = noise(n)
    out = []
    ph1 = ph2 = 0.0
    for i in range(n):
        t = i / SR
        ph1 += 2 * math.pi * (4380 + 60 * math.sin(t * 0.7)) / SR
        ph2 += 2 * math.pi * 4710 / SR
        buzz = math.sin(ph1) * 0.6 + math.sin(ph2) * 0.4 + rnd[i] * 0.35
        trem = 0.55 + 0.45 * (1.0 if math.sin(2 * math.pi * 50 * t) > 0.2 else 0.0)
        swell = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(2 * math.pi * t / 4.0)) ** 2
        far = 0.6 + 0.4 * math.sin(2 * math.pi * t / 2.7 + 1.0)
        out.append(buzz * trem * swell * far)
    return loopify(highpass(out, 0.3), 0.5)


def main(root, only=""):
    sfx = os.path.join(root, "assets", "audio", "sfx")
    if only == "cicada":
        write(os.path.join(sfx, "cicada.wav"), cicada(), 0.35)
        print("ok")
        return
    sfx = os.path.join(root, "assets", "audio", "sfx")
    mus = os.path.join(root, "assets", "audio", "music")
    write(os.path.join(sfx, "hose.wav"), hose(), 0.5)
    write(os.path.join(sfx, "crackle.wav"), crackle(), 0.6)
    write(os.path.join(sfx, "siren.wav"), siren(), 0.35)
    write(os.path.join(sfx, "sizzle.wav"), sizzle(), 0.4)
    write(os.path.join(mus, "theme.wav"), theme(), 0.7)
    write(os.path.join(sfx, "cicada.wav"), cicada(), 0.35)
    print("ok")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else "")
