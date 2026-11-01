"""Original 96-second, 70 BPM ambient electric-piano loop. No external samples.
Requires numpy. Run from project root; writes assets/audio/music/chill.wav.
"""
from pathlib import Path
import wave
import numpy as np

SR = 32000
BEAT = 60 / 70
LENGTH = 28 * 4 * BEAT
N = round(LENGTH * SR)
mix = np.zeros((N, 2), dtype=np.float64)
rng = np.random.default_rng(31)

def note(midi, start, duration, gain, pan=0., pad=False):
    t = np.arange(round(duration * SR)) / SR
    f = 440 * 2 ** ((midi-69) / 12)
    if pad:
        signal = (np.sin(2*np.pi*f*t) + .22*np.sin(2*np.pi*f*1.0015*t)
                  + .12*np.sin(2*np.pi*f*2*t))
        env = np.sin(np.pi*np.minimum(t/duration, 1)) ** 2
    else:
        # Soft attack, subdued tines and long exponential decay.
        signal = (np.sin(2*np.pi*f*t + .65*np.sin(2*np.pi*f*t)*np.exp(-t*2))
                  + .12*np.sin(2*np.pi*f*2*t)*np.exp(-t*2.5))
        env = (1-np.exp(-t*35))*np.exp(-t/1.7)*np.minimum(1,(duration-t)/.35)
    signal *= env*gain
    idx = (np.arange(len(t))+round(start*SR)) % N
    mix[idx, 0] += signal*np.sqrt((1-pan)/2)
    mix[idx, 1] += signal*np.sqrt((1+pan)/2)

# Dmaj9, Bm7, Gmaj9, A6: spacious voicings, no busy lead or percussion.
chords = [(38,[54,57,61,64]),(35,[54,57,62,66]),
          (31,[54,57,62,69]),(33,[52,57,61,66])]
for bar in range(28):
    bass, chord = chords[(bar//2) % 4]
    start = bar*4*BEAT
    for i, key in enumerate(chord):
        note(key, start+i*.065, 5.5, .065, (i-1.5)*.25)
        if bar % 2 == 0: note(key-12, start, 8*BEAT, .020, (1.5-i)*.2, True)
    note(bass, start, 4*BEAT, .055, 0)
    if bar % 2 == 1:
        for beat, key in [(1.5,chord[2]+12),(3.,chord[1]+12)]:
            note(key, start+beat*BEAT, 3.0, .030, rng.uniform(-.4,.4))

# Wrapped stereo room reflections preserve a seamless loop, including note tails.
dry = mix.copy()
for seconds, gain in [(.19,.16),(.37,.11),(.61,.08),(.89,.05),(1.23,.03)]:
    mix += np.roll(dry[:, ::-1],round(seconds*SR),axis=0)*gain
mix *= .62 / np.max(np.abs(mix))
pcm = np.round(mix*32767).astype('<i2')
output = Path('assets/audio/music/chill.wav')
with wave.open(str(output),'wb') as f:
    f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR); f.writeframes(pcm.tobytes())
assert np.max(np.abs(pcm.astype(float))) < 32767
assert np.max(np.abs(mix[0]-mix[-1])) < .015
print(f'{output}: {LENGTH:.1f}s, stereo, peak {np.max(np.abs(mix)):.2f}, RMS {np.sqrt(np.mean(mix**2)):.3f}, seamless boundary checked')
