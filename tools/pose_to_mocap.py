#!/usr/bin/env python3
"""pose_raw.json (MediaPipe world landmarks) -> mocap.json for VitChar.apply_dirs():
per frame: limb directions in character space (X = character's left, Y up, Z toward camera), root yaw,
visibility flags. Gaussian-smoothed over time; legs fall back to a standing pose when out of frame."""
import json, sys, numpy as np
raw = json.load(open(sys.argv[1])); fps = raw["fps"]; fr = raw["frames"]
n = len(fr); L = np.full((n, 33, 4), np.nan)
for i, f in enumerate(fr):
    if f: L[i] = np.array(f)
# fill missing frames by nearest valid, then smooth positions (sigma 1.5 frames)
valid = ~np.isnan(L[:, 0, 0])
idx = np.where(valid)[0]
for i in range(n):
    if not valid[i]:
        L[i] = L[idx[np.argmin(np.abs(idx - i))]]
def smooth(a, s=1.5):
    k = np.exp(-0.5 * (np.arange(-4, 5) / s) ** 2); k /= k.sum()
    pad = np.pad(a, ((4, 4),) + ((0, 0),) * (a.ndim - 1), mode="edge")
    return np.apply_along_axis(lambda v: np.convolve(v, k, mode="valid"), 0, pad)
P = smooth(L[:, :, :3]); V = L[:, :, 3]
# MediaPipe world: x screen-right, y down, z toward camera negative  ->  Godot char: X = x, Y = -y, Z = -z
P = P * np.array([1, -1, -1])
I = dict(nose=0, lear=7, rear=8, lsh=11, rsh=12, lel=13, rel=14, lwr=15, rwr=16, lhip=23, rhip=24, lkn=25, rkn=26, lan=27, ran=28)
def D(a, b): return P[:, I[b]] - P[:, I[a]]
hipC = (P[:, I["lhip"]] + P[:, I["rhip"]]) / 2; shC = (P[:, I["lsh"]] + P[:, I["rsh"]]) / 2
earC = (P[:, I["lear"]] + P[:, I["rear"]]) / 2
dirs = {"chest": shC - hipC, "head": earC - shC,
        "lsh": D("lsh", "lel"), "lel": D("lel", "lwr"), "rsh": D("rsh", "rel"), "rel": D("rel", "rwr"),
        "lhip": D("lhip", "lkn"), "lknee": D("lkn", "lan"), "rhip": D("rhip", "rkn"), "rknee": D("rkn", "ran")}
# root yaw from the shoulder line (right->left shoulder is +X at rest); limb dirs expressed in that frame
s = P[:, I["lsh"]] - P[:, I["rsh"]]
yaw = np.arctan2(-s[:, 2], s[:, 0])
yaw = smooth(yaw[:, None], 3.0)[:, 0]
def unyaw(v):
    c, sn = np.cos(-yaw), np.sin(-yaw)
    return np.stack([c * v[:, 0] + sn * v[:, 2], v[:, 1], -sn * v[:, 0] + c * v[:, 2]], 1)
out = []
legvis = np.minimum.reduce([V[:, I["lkn"]], V[:, I["rkn"]], V[:, I["lan"]], V[:, I["ran"]]])
beat = np.arange(n) / fps * 128 / 60
for i in range(n):
    d = {k: unyaw(v)[i] for k, v in dirs.items()}
    if legvis[i] < 0.5:   # legs out of frame: stand, knees pulsing a little on the beat
        flex = 0.12 * abs(np.sin(np.pi * beat[i]))
        for k in ("lhip", "rhip"): d[k] = np.array([0, -1, flex])
        for k in ("lknee", "rknee"): d[k] = np.array([0, -1, -flex * 0.6])
    out.append({"yaw": float(yaw[i]), "legs_tracked": bool(legvis[i] >= 0.5),
                "dirs": {k: [round(float(x), 4) for x in (v / (np.linalg.norm(v) + 1e-9))] for k, v in d.items()}})
json.dump({"fps": fps, "frames": out}, open(sys.argv[2], "w"))
print("frames", n, "legs tracked", int((legvis >= 0.5).sum()), "yaw range deg", np.degrees(yaw.min()).round(1), np.degrees(yaw.max()).round(1))
