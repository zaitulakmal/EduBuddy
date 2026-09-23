#!/usr/bin/env python3
"""Synthesises the story library's interactive sounds and ambient loops.

Everything is generated from sine waves and filtered noise, so the output is
original and royalty free. Writes AAC .m4a files next to the existing SFX:

  assets/audio/story_<name>.m4a   one-shot tap sounds
  assets/audio/amb_<name>.m4a     12 s seamless ambient loops

Usage (needs numpy and ffmpeg):
  python3 tool/synth_story_sounds.py
"""

import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
rng = np.random.default_rng(42)


# ── Building blocks ─────────────────────────────────────────────────────────

def times(dur):
    return np.arange(int(SR * dur)) / SR


def tone(freq, dur, phase=0.0):
    """Sine with a per-sample frequency array or constant."""
    t = times(dur)
    f = np.broadcast_to(np.asarray(freq, dtype=float), t.shape)
    return np.sin(2 * np.pi * np.cumsum(f) / SR + phase)


def sweep(f0, f1, dur, curve=1.0):
    t = times(dur)
    k = (t / dur) ** curve
    return tone(f0 + (f1 - f0) * k, dur)


def env(dur, attack=0.005, decay=8.0):
    t = times(dur)
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    return a * np.exp(-t * decay)


def noise(dur):
    return rng.standard_normal(int(SR * dur))


def band(x, lo, hi):
    """Brick-wall band-pass in the frequency domain (fine for textures)."""
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / SR)
    spec[(freqs < lo) | (freqs > hi)] = 0
    return np.fft.irfft(spec, len(x))


def pink(dur):
    x = noise(dur)
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / SR)
    spec[1:] /= np.sqrt(freqs[1:])
    spec[0] = 0
    return np.fft.irfft(spec, len(x))


def place(buf, clip, at):
    start = int(at * SR)
    end = min(len(buf), start + len(clip))
    if start < len(buf):
        buf[start:end] += clip[: end - start]
    return buf


def silence(dur):
    return np.zeros(int(SR * dur))


def normalise(x, peak=0.7):
    m = np.max(np.abs(x))
    return x if m == 0 else x / m * peak


def level(x, rms=0.125, peak=0.8):
    """Evens out loudness: aims for a target RMS without letting peaks clip."""
    r = np.sqrt(np.mean(x ** 2))
    m = np.max(np.abs(x))
    if r == 0 or m == 0:
        return x
    return x * min(rms / r, peak / m)


def fade_edges(x, ms=6):
    n = int(SR * ms / 1000)
    ramp = np.linspace(0, 1, n)
    x = x.copy()
    x[:n] *= ramp
    x[-n:] *= ramp[::-1]
    return x


def bell(freq, dur, decay=6.0):
    t = times(dur)
    x = (np.sin(2 * np.pi * freq * t)
         + 0.5 * np.sin(2 * np.pi * freq * 2.76 * t) * np.exp(-t * decay * 1.5)
         + 0.25 * np.sin(2 * np.pi * freq * 5.4 * t) * np.exp(-t * decay * 2.5))
    return x * env(dur, 0.002, decay)


def pluck(freq, dur):
    t = times(dur)
    x = sum(np.sin(2 * np.pi * freq * h * t) / h for h in (1, 2, 3))
    return x * env(dur, 0.002, 7)


# ── One-shot tap sounds ─────────────────────────────────────────────────────

def s_pop():
    d = 0.14
    return sweep(900, 260, d, 0.5) * env(d, 0.002, 30) + band(noise(d), 2000, 6000) * env(d, 0.001, 120) * 0.3


def s_boing():
    d = 0.55
    t = times(d)
    f = 240 * (1 + 0.45 * np.exp(-t * 7) * np.sin(2 * np.pi * 16 * t)) + 60 * t
    return tone(f, d) * env(d, 0.004, 5)


def s_hop():
    one = sweep(380, 950, 0.11, 0.7) * env(0.11, 0.003, 18)
    return np.concatenate([one, silence(0.05), one * 0.8])


def s_patter():
    buf = silence(0.35)
    for i in range(7):
        click = band(noise(0.008), 2500, 8000) * env(0.008, 0.0005, 400)
        place(buf, click * (0.6 + 0.4 * rng.random()), i * 0.045 + rng.random() * 0.01)
    return buf


def s_chirp():
    buf = silence(0.5)
    for i in range(3):
        d = 0.09
        t = times(d)
        pulse = np.sin(2 * np.pi * 4300 * t) * (0.5 + 0.5 * np.sin(2 * np.pi * 45 * t)) * env(d, 0.005, 12)
        place(buf, pulse, i * 0.14)
    return buf


def s_bonk():
    d = 0.35
    x = sweep(170, 90, d, 0.4) + 0.4 * sweep(510, 270, d, 0.4)
    return x * env(d, 0.002, 14) + band(noise(d), 800, 3000) * env(d, 0.001, 90) * 0.2


def s_chomp():
    buf = silence(0.5)
    for at in (0.0, 0.22):
        d = 0.14
        c = band(noise(d), 150, 1200) * env(d, 0.004, 22) + sweep(160, 70, d) * env(d, 0.002, 25) * 0.8
        place(buf, c, at)
    return buf


def s_bubble():
    buf = silence(0.45)
    for i, f in enumerate((500, 700, 950)):
        d = 0.08
        place(buf, sweep(f, f * 2.4, d, 0.6) * env(d, 0.002, 30), i * 0.12)
    return buf


def s_clack():
    buf = silence(0.35)
    for at in (0.0, 0.09, 0.2, 0.29):
        d = 0.03
        place(buf, band(noise(d), 2500, 6000) * env(d, 0.0005, 160), at)
    return buf


def s_tweet():
    buf = silence(0.5)
    for at in (0.0, 0.2):
        d = 0.16
        t = times(d)
        f = 2600 + 1400 * np.sin(np.pi * t / d) + 120 * np.sin(2 * np.pi * 40 * t)
        place(buf, tone(f, d) * env(d, 0.01, 10), at)
    return buf


def s_flutter():
    d = 0.5
    t = times(d)
    x = band(noise(d), 600, 3500) * (0.5 + 0.5 * np.sin(2 * np.pi * 22 * t))
    return x * np.sin(np.pi * t / d) * 0.8


def s_munch():
    buf = silence(0.5)
    for i in range(3):
        d = 0.09
        place(buf, band(noise(d), 900, 4000) * env(d, 0.002, 30), i * 0.15)
    return buf


def s_crack():
    d = 0.4
    buf = band(noise(d), 1500, 9000) * env(d, 0.001, 60)
    for _ in range(5):
        place(buf, band(noise(0.01), 3000, 9000) * env(0.01, 0.0005, 300) * 0.6, 0.05 + rng.random() * 0.25)
    return buf


def s_twinkle():
    notes = (1047, 1319, 1568, 2093)
    buf = silence(0.75)
    for i, f in enumerate(notes):
        place(buf, bell(f, 0.4, 9) * 0.6, i * 0.07)
    return buf


def s_coin():
    buf = silence(0.45)
    for at, f in ((0.0, 988), (0.08, 1319)):
        d = 0.35
        t = times(d)
        sq = sum(np.sin(2 * np.pi * f * h * t) / h for h in (1, 3, 5))
        place(buf, sq * env(d, 0.002, 9) * 0.6, at)
    return buf


def s_whoosh():
    d = 0.65
    t = times(d)
    x = np.zeros_like(t)
    chunks = 26
    size = len(t) // chunks
    for i in range(chunks):
        k = i / chunks
        centre = 300 + 1800 * np.sin(np.pi * k)
        seg = band(noise(d), centre * 0.6, centre * 1.4)[:size]
        x[i * size:(i + 1) * size] = seg
    return x * np.sin(np.pi * t / d) ** 2


def s_drip():
    d = 0.1
    one = sweep(1100, 2600, d, 0.4) * env(d, 0.001, 40)
    buf = silence(0.4)
    place(buf, one, 0)
    place(buf, one * 0.3, 0.16)
    return buf


def s_chime():
    return bell(880, 1.0, 4) + bell(1320, 1.0, 5) * 0.4


def s_space():
    d = 0.8
    t = times(d)
    f = 260 + 500 * (t / d) + 90 * np.sin(2 * np.pi * 7 * t)
    return tone(f, d) * np.sin(np.pi * t / d) * 0.8


def s_gliss():
    scale = (523, 587, 659, 784, 880, 1047, 1175, 1319, 1568, 1760, 2093, 2349)
    buf = silence(1.0)
    for i, f in enumerate(scale):
        place(buf, pluck(f, 0.35) * 0.45, i * 0.04)
    return buf


def s_firework():
    buf = silence(1.1)
    d = 0.35
    place(buf, sweep(700, 2200, d, 0.8) * np.linspace(0.2, 0.7, int(SR * d)), 0)
    boom = band(noise(0.5), 60, 2500) * env(0.5, 0.002, 9)
    place(buf, boom, 0.35)
    for _ in range(16):
        place(buf, band(noise(0.012), 2000, 9000) * env(0.012, 0.0005, 250) * 0.5, 0.45 + rng.random() * 0.55)
    return buf


def s_beep():
    buf = silence(0.45)
    for at in (0.0, 0.2):
        d = 0.15
        t = times(d)
        sq = sum(np.sin(2 * np.pi * 520 * h * t) / h for h in (1, 3, 5, 7))
        place(buf, sq * np.clip(t / 0.01, 0, 1) * np.clip((d - t) / 0.02, 0, 1) * 0.5, at)
    return buf


SFX = {
    'pop': s_pop, 'boing': s_boing, 'hop': s_hop, 'patter': s_patter,
    'chirp': s_chirp, 'bonk': s_bonk, 'chomp': s_chomp, 'bubble': s_bubble,
    'clack': s_clack, 'tweet': s_tweet, 'flutter': s_flutter, 'munch': s_munch,
    'crack': s_crack, 'twinkle': s_twinkle, 'coin': s_coin, 'whoosh': s_whoosh,
    'drip': s_drip, 'chime': s_chime, 'space': s_space, 'gliss': s_gliss,
    'firework': s_firework, 'beep': s_beep,
}


# ── Ambient loops ───────────────────────────────────────────────────────────

LOOP = 12.0
TAIL = 1.0


def loopify(x):
    """Folds the extra tail back over the head so the loop point is seamless."""
    n = int(SR * LOOP)
    f = int(SR * TAIL)
    out = x[:n].copy()
    ramp = np.linspace(0, 1, f)
    out[:f] = x[:f] * ramp + x[n:n + f] * (1 - ramp)
    return out


def bed(lo, hi, amount=1.0):
    return band(pink(LOOP + TAIL), lo, hi) * amount


def scatter(buf, clip_fn, count, gain):
    for _ in range(count):
        place(buf, clip_fn() * gain * (0.5 + 0.5 * rng.random()), rng.random() * (LOOP + TAIL - 1))
    return buf


def slow_am(period, depth, dur=LOOP + TAIL, offset=0.0):
    t = times(dur)
    return 1 - depth + depth * (0.5 + 0.5 * np.sin(2 * np.pi * t / period + offset))


def a_day():
    x = normalise(bed(150, 1200), 0.25) * slow_am(6, 0.5)
    return scatter(x, s_tweet, 5, 0.18)


def a_night():
    x = normalise(bed(100, 600), 0.08)
    for freq, rate, gain in ((4500, 0.55, 0.14), (3800, 0.8, 0.1)):
        t = times(LOOP + TAIL)
        pulses = (np.sin(2 * np.pi * t / rate) > 0.6).astype(float)
        # Soft edges: hard-gated high tones make the AAC encoder overshoot.
        pulses = np.convolve(pulses, np.hanning(2400) / np.hanning(2400).sum(), mode='same')
        x += np.sin(2 * np.pi * freq * t) * (0.5 + 0.5 * np.sin(2 * np.pi * 40 * t)) * pulses * gain
    return x


def a_forest():
    t = times(LOOP + TAIL)
    x = normalise(bed(200, 1500), 0.18) * slow_am(4, 0.4)
    x += normalise(band(noise(LOOP + TAIL), 5000, 7000), 0.05) * (0.6 + 0.4 * np.sin(2 * np.pi * 9 * t))
    scatter(x, s_tweet, 6, 0.14)
    return scatter(x, s_chirp, 3, 0.08)


def a_river():
    t = times(LOOP + TAIL)
    x = normalise(bed(250, 3000), 0.3)
    x *= 0.7 + 0.3 * np.abs(np.sin(2 * np.pi * 3.3 * t) * np.sin(2 * np.pi * 1.7 * t))
    return scatter(x, s_bubble, 6, 0.08)


def a_waves():
    x = normalise(bed(80, 2500), 0.45)
    swell = slow_am(6, 0.85) ** 2
    return x * swell


def a_underwater():
    x = normalise(bed(40, 350), 0.4) * slow_am(4, 0.3)
    return scatter(x, s_bubble, 10, 0.12)


def a_space():
    t = times(LOOP + TAIL)
    x = sum(np.sin(2 * np.pi * f * t) * (0.6 + 0.4 * np.sin(2 * np.pi * t / (3 + i) + i))
            for i, f in enumerate((110, 165, 220.5, 330)))
    x = normalise(x, 0.18)
    return scatter(x, lambda: bell(1760, 1.0, 3), 4, 0.05)


def a_market():
    t = times(LOOP + TAIL)
    x = np.zeros_like(t)
    for i in range(5):
        voice = band(noise(LOOP + TAIL), 250 + i * 60, 900 + i * 80)
        syll = np.clip(np.sin(2 * np.pi * (4 + i * 0.9) * t + i * 2) * np.sin(2 * np.pi * t / (2.5 + i)), 0, 1)
        x += voice * syll
    x = normalise(x, 0.25)
    return scatter(x, lambda: bell(2400, 0.2, 20), 8, 0.06)


def a_home():
    x = normalise(bed(60, 400), 0.05)
    for i in range(int(LOOP + TAIL)):
        tick = band(noise(0.02), 1500, 5000) * env(0.02, 0.0005, 200) * (0.12 if i % 2 else 0.09)
        place(x, tick, i + 0.02)
    return x


def a_wind():
    t = times(LOOP + TAIL)
    x = np.zeros_like(t)
    for lo, hi, period in ((200, 700, 6), (500, 1500, 4), (900, 2500, 3)):
        x += normalise(band(pink(LOOP + TAIL), lo, hi), 1) * slow_am(period, 0.9, offset=lo / 300)
    return normalise(x, 0.35)


def a_rain():
    x = normalise(band(noise(LOOP + TAIL), 1200, 12000), 0.22)
    x += normalise(bed(200, 1200), 0.12)
    return scatter(x, lambda: s_drip() * 0.5, 30, 0.12)


AMBIENT = {
    'day': a_day, 'night': a_night, 'forest': a_forest, 'river': a_river,
    'waves': a_waves, 'underwater': a_underwater, 'space': a_space,
    'market': a_market, 'home': a_home, 'wind': a_wind, 'rain': a_rain,
}


# ── Output ──────────────────────────────────────────────────────────────────

def write_m4a(x, path, bitrate):
    pcm = np.clip(x, -1, 1)
    pcm = (pcm * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
        wav_path = tmp.name
    with wave.open(wav_path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(
        ['ffmpeg', '-y', '-loglevel', 'error', '-i', wav_path, '-c:a', 'aac', '-b:a', bitrate, '-ac', '1', path],
        check=True,
    )
    os.remove(wav_path)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in SFX.items():
        write_m4a(level(fade_edges(fn())), os.path.join(OUT, f'story_{name}.m4a'), '48k')
        print('story', name)
    for name, fn in AMBIENT.items():
        x = loopify(fn())
        write_m4a(level(x, rms=0.1, peak=0.6), os.path.join(OUT, f'amb_{name}.m4a'), '64k')
        print('ambient', name)


if __name__ == '__main__':
    main()
