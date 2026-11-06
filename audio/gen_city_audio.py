#!/usr/bin/env python3
"""Original, copyright-free score + SFX for city-chase-1080p.mp4 (20 s), synthesized from scratch.

Event times follow city.gd: SPEED 28, turn at t_turn = 8.75 s, cuts at 6.95 / 11.45 s,
wanted stars at 3.0 / 6.0 / 9.55 s, fade from 17.2 s.
    python3 gen_city_audio.py OUT.wav
"""
import sys, wave
import numpy as np
from scipy.signal import butter, sosfilt

SR, DUR = 48000, 20.04
BPM = 130
BEAT = 60 / BPM
T_TURN = 245.0 / 28.0
CUTS = (T_TURN - 1.8, T_TURN + 2.7)
STARS = (3.0, 6.0, T_TURN + 0.8)
rng = np.random.default_rng(11)
N = int(DUR * SR)
t_all = np.arange(N) / SR


def note(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def env(n, a, d):
    t = np.arange(n) / SR
    return np.minimum(t / a, 1.0) * np.exp(-t / d)


def saw(f, dur, d, a=.004, det=0.0):
    n = int(dur * SR); t = np.arange(n) / SR
    w = sum(((f * (1 + s * det) * t) % 1.0) * 2 - 1 for s in (-1, 0, 1)) / 3
    return w * env(n, a, d)


def sine(f, dur, d, a=.003):
    n = int(dur * SR); t = np.arange(n) / SR
    return np.sin(2 * np.pi * f * t) * env(n, a, d)


def lp(x, fc):
    return sosfilt(butter(2, fc, 'low', fs=SR, output='sos'), x)


def bp(x, lo, hi):
    return sosfilt(butter(2, [lo, hi], 'band', fs=SR, output='sos'), x)


def mix(buf, x, at, g=1.0):
    i = int(at * SR); j = min(len(buf), i + len(x))
    if 0 <= i < len(buf):
        buf[i:j] += g * x[:j - i]


def music():
    L = np.zeros(N); R = np.zeros(N)
    prog = [[57, 60, 64], [53, 57, 60], [50, 53, 57], [52, 56, 59]]   # Am F Dm E
    bars = int(17.2 / (4 * BEAT)) + 1
    for b in range(bars):
        ch = prog[b % 4]; t0 = 1.0 + b * 4 * BEAT
        for s in range(16):                                   # 16th bass ostinato
            t = t0 + s * BEAT / 4
            if t > 17.2: break
            m = ch[0] - 24 + (12 if s % 4 == 2 else 0)
            x = lp(saw(note(m), BEAT / 4 * .95, .09, det=.004), 900) * .22
            mix(L, x, t); mix(R, x, t)
        for k, m in enumerate(ch):                            # synth stab on 1 and the "and" of 2
            for off in (0.0, 1.5):
                if t0 + off * BEAT > 17.2: continue
                x = lp(saw(note(m + 12), BEAT * .45, .16, det=.008), 2800) * .07
                mix(L, x, t0 + off * BEAT, 1.0 if k != 1 else .5); mix(R, x, t0 + off * BEAT, .5 if k != 1 else 1.0)
        for q in range(4):
            t = t0 + q * BEAT
            if t > 17.2: break
            kn = int(.22 * SR); tt = np.arange(kn) / SR             # kick
            k = np.sin(2 * np.pi * (48 + 110 * np.exp(-tt * 35)) * tt) * np.exp(-tt * 14) * .45
            mix(L, k, t); mix(R, k, t)
            if q in (1, 3):                                         # snare
                sn = int(.2 * SR)
                s = bp(rng.standard_normal(sn), 800, 6000) * env(sn, .001, .06) * .22 + sine(190, .2, .05) * .12
                mix(L, s, t); mix(R, s, t)
            for h in range(4):                                      # 16th hats
                hn = int(.04 * SR)
                x = bp(rng.standard_normal(hn), 7000, 14000) * env(hn, .001, .012) * (.09 if h % 2 else .05)
                mix(L if h % 2 else R, x, t + h * BEAT / 4)
    for k, m in enumerate([57, 60, 64, 69]):                         # final hit at 17.2
        x = lp(saw(note(m), 2.8, .9, det=.01), 2200) * .12
        mix(L, x, 17.2, 1.0 if k % 2 else .6); mix(R, x, 17.2, .6 if k % 2 else 1.0)
    rn = int(1.0 * SR); rt = np.arange(rn) / SR                       # intro riser 0-1 s
    riser = bp(rng.standard_normal(rn), 400, 6000) * (rt / 1.0) ** 2 * .12
    mix(L, riser, 0.0); mix(R, riser, 0.0)
    return L, R


def engine_gain(t):
    g = np.where(t < CUTS[0], 1.0, np.where(t < CUTS[1], 0.0, 0.85))
    dist = np.abs(28.0 * (t - T_TURN)) + 6.0                          # shot B: static camera at the corner
    gb = np.clip(14.0 / dist, 0.05, 1.0)
    return np.where((t >= CUTS[0]) & (t < CUTS[1]), gb, g)


def engine():
    t = t_all
    rel = 28.0 * (t - T_TURN)
    dop = np.where((t >= CUTS[0]) & (t < CUTS[1]), 340.0 / (340.0 + 28.0 * np.tanh(rel / 6.0)), 1.0)
    f = 62.0 * dop * (1 + .015 * np.sin(2 * np.pi * 7 * t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) + .6 * np.sin(2 * ph + .3) + .45 * np.sign(np.sin(3 * ph)) * .5 + .3 * np.sin(4 * ph)
    x = lp(x + .25 * lp(rng.standard_normal(N), 300), 1400)
    return x * engine_gain(t) * .16


def siren():
    t = t_all
    lfo = .5 - .5 * np.cos(2 * np.pi * t / 1.6)
    f = 700 + 650 * lfo
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) + .3 * np.sin(2 * ph) + .15 * np.sin(3 * ph)
    gap = np.maximum(30.0 - 8.0 * np.clip((t - 8.0) / 6.0, 0, 1), 8.0)
    g = np.clip(18.0 / gap, 0, 1) * np.minimum(t / 2.0, 1.0)
    g = np.where((t >= CUTS[0]) & (t < CUTS[1]), np.clip(14.0 / (np.abs(28.0 * (t - T_TURN) - gap) + 6.0), .05, 1.0), g)
    return lp(x, 3500) * g * .08


def main(out):
    L, R = music()
    e = engine(); s = siren()
    L += e; R += e
    L += s * .8; R += s
    for c in CUTS:                                                    # whoosh on cuts
        wn = int(.6 * SR); wt = np.arange(wn) / SR
        w = bp(rng.standard_normal(wn), 300, 5000) * np.sin(np.pi * wt / .6) ** 2 * .25
        mix(L, w, c - .3); mix(R, w, c - .3)
    sn = int(1.5 * SR); st = np.arange(sn) / SR                        # tyre screech
    sq = bp(rng.standard_normal(sn), 1800, 4200) * .5 + np.sin(2 * np.pi * (1250 + 80 * np.sin(2 * np.pi * 9 * st)) * st) * .4
    sq *= np.minimum(st / .08, 1) * np.minimum((1.5 - st) / .4, 1) * .22
    mix(L, sq, T_TURN - .4); mix(R, sq, T_TURN - .4, .8)
    for t in STARS:                                                   # wanted-level ping
        p = sine(note(88), .5, .18) * .12 + sine(note(93), .5, .2) * .1
        mix(L, p, t); mix(R, p, t + .06)
    mission = sine(note(69), .25, .1) * .1                             # mission stinger
    mix(L, mission, .8); mix(R, mission, .8); mix(L, sine(note(76), .5, .25) * .12, .95); mix(R, sine(note(76), .5, .25) * .12, .95)
    hn = int(.45 * SR); ht = np.arange(hn) / SR                        # car horn
    horn = (np.sign(np.sin(2 * np.pi * 415 * ht)) + np.sign(np.sin(2 * np.pi * 523 * ht))) * env(hn, .01, .6) * np.minimum((.45 - ht) / .05, 1)
    mix(R, lp(horn, 2500) * .05, 4.3); mix(L, lp(horn, 2500) * .03, 4.3)
    st2 = np.stack([L, R], 1)
    st2[:int(.05 * SR)] *= np.linspace(0, 1, int(.05 * SR))[:, None]
    tail = int(2.0 * SR)
    st2[-tail:] *= np.linspace(1, 0, tail)[:, None] ** 1.5
    st2 /= np.max(np.abs(st2)) / 0.89
    with wave.open(out, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((st2 * 32767).astype(np.int16).tobytes())


if __name__ == "__main__":
    main(sys.argv[1])
