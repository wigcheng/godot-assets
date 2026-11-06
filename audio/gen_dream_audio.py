#!/usr/bin/env python3
"""Original, copyright-free DJ-style track + SFX for dream.tscn (23 s). No melody from the original song.

128 BPM (same grid as the dance poses), D minor, Dm-Bb-C-A. Whip pans at 11.0 / 19.0 s, fade from 21.4 s.
    python3 gen_dream_audio.py OUT.wav
"""
import sys, wave
import numpy as np
from scipy.signal import butter, sosfilt

SR, DUR = 48000, 23.04
BPM = 128
BEAT = 60 / BPM
WHIPS = (11.0, 19.0)
END = 21.4
rng = np.random.default_rng(5)
N = int(DUR * SR)
t_all = np.arange(N) / SR


def note(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def env(n, a, d):
    t = np.arange(n) / SR
    return np.minimum(t / a, 1.0) * np.exp(-t / d)


def saw(f, dur, d, a=.004, det=.0):
    n = int(dur * SR); t = np.arange(n) / SR
    w = sum(((f * (1 + s * det) * t) % 1.0) * 2 - 1 for s in (-1, 0, 1)) / 3
    return w * env(n, a, d)


def sine(f, dur, d, a=.003):
    n = int(dur * SR); t = np.arange(n) / SR
    return np.sin(2 * np.pi * f * t) * env(n, a, d)


def filt(x, fc, kind='low'):
    return sosfilt(butter(2, fc, kind, fs=SR, output='sos'), x)


def mix(buf, x, at, g=1.0):
    i = int(at * SR); j = min(len(buf), i + len(x))
    if 0 <= i < len(buf):
        buf[i:j] += g * x[:j - i]


def main(out):
    L = np.zeros(N); R = np.zeros(N)
    music = np.zeros(N); musicR = np.zeros(N)
    prog = [[50, 53, 57], [46, 50, 53], [48, 52, 55], [45, 49, 52]]          # Dm Bb C A
    hook = [[74, 77, 81, 79, 77, 76, 74, 72], [70, 74, 77, 76, 74, 72, 70, 69],
            [72, 76, 79, 77, 76, 74, 72, 76], [69, 73, 76, 74, 73, 76, 81, 81]]
    bars = int(END / (4 * BEAT)) + 1
    for b in range(bars):
        t0 = b * 4 * BEAT
        ch = prog[b % 4]
        intro = t0 < 1.8
        sec_b = WHIPS[0] + .2 <= t0 < WHIPS[1]
        for k, m in enumerate(ch):                                           # pad
            p = filt(saw(note(m), 4 * BEAT, 3.0, a=.05, det=.006), 1400 if not intro else 500) * .05
            mix(music, p, t0, 1.0 if k != 1 else .5); mix(musicR, p, t0, .5 if k != 1 else 1.0)
        for q in range(4):
            t = t0 + q * BEAT
            if t >= END: break
            for h8 in (0, .5):                                               # rolling bass on 8ths
                x = filt(saw(note(ch[0] - 24 + (12 if h8 else 0)), BEAT * .45, .12, det=.003), 700) * .2
                mix(music, x, t + h8 * BEAT); mix(musicR, x, t + h8 * BEAT)
            if intro:
                continue
            kn = int(.25 * SR); tt = np.arange(kn) / SR                    # kick
            k = np.sin(2 * np.pi * (45 + 120 * np.exp(-tt * 30)) * tt) * np.exp(-tt * 10) * .55
            mix(L, k, t); mix(R, k, t)
            hn = int(.12 * SR)                                               # open hat on the off-beat
            oh = filt(rng.standard_normal(hn), 6000, 'high') * env(hn, .002, .05) * .09
            mix(L, oh, t + BEAT / 2, .8); mix(R, oh, t + BEAT / 2)
            if q in (1, 3):                                                  # clap
                cn = int(.2 * SR)
                c = filt(rng.standard_normal(cn), 1200, 'high') * env(cn, .002, .07) * .16
                mix(L, c, t); mix(R, c, t)
            for e in range(2):                                               # lead hook (original)
                m = hook[b % 4][q * 2 + e] + (12 if sec_b else 0)
                x = filt(saw(note(m), BEAT * .48, .22, det=.01), 4200) * .085
                mix(L, x, t + e * BEAT / 2, .9); mix(R, x, t + e * BEAT / 2 + .012, .9)
    phase = (t_all % BEAT) / BEAT                                            # sidechain pump
    pump = np.where(t_all < 1.875, 1.0, 1.0 - .75 * np.exp(-phase * 7))
    L += music * pump; R += musicR * pump
    for w in WHIPS:
        rn = int(.9 * SR); rt = np.arange(rn) / SR                         # riser into the whip
        riser = filt(rng.standard_normal(rn), 800, 'high') * (rt / .9) ** 2 * .14
        sweep = np.sin(2 * np.pi * np.cumsum(300 + 1500 * (rt / .9) ** 2) / SR) * (rt / .9) ** 2 * .05
        mix(L, riser + sweep, w - .9); mix(R, riser + sweep, w - .9)
        wn = int(.5 * SR); wt = np.arange(wn) / SR                          # whoosh
        wh = filt(rng.standard_normal(wn), 4000) * np.sin(np.pi * wt / .5) ** 2 * .3
        mix(L, wh, w, 1.0); mix(R, wh * .6, w)
        cn = int(1.4 * SR)                                                  # crash on landing
        crash = filt(rng.standard_normal(cn), 3000, 'high') * env(cn, .002, .45) * .12
        mix(L, crash, w + .22); mix(R, crash, w + .22)
    for k, m in enumerate([50, 57, 62, 65, 69]):                            # final hit
        x = filt(saw(note(m), 1.6, .7, det=.01), 2500) * .1
        mix(L, x, END, 1.0 if k % 2 else .6); mix(R, x, END, .6 if k % 2 else 1.0)
    kn = int(.6 * SR); tt = np.arange(kn) / SR
    boom = np.sin(2 * np.pi * (35 + 80 * np.exp(-tt * 15)) * tt) * np.exp(-tt * 4) * .6
    mix(L, boom, END); mix(R, boom, END)
    st = np.stack([L, R], 1)
    st[:int(.03 * SR)] *= np.linspace(0, 1, int(.03 * SR))[:, None]
    tail = int(1.4 * SR)
    st[-tail:] *= np.linspace(1, 0, tail)[:, None] ** 1.5
    st /= np.max(np.abs(st)) / 0.89
    with wave.open(out, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((st * 32767).astype(np.int16).tobytes())


if __name__ == "__main__":
    main(sys.argv[1])
