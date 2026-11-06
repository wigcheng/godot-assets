#!/usr/bin/env python3
"""Build the board-ready Vitruvian files from upstream/godot_project into ./out/:
  vitruvian_body.glb (copied)            vitruvian_head_lite.glb (UV0 only)   scalp_cap.glb (buzz cut)
  brows_lite.glb (brow cards only)       hair_rgba.png / brow_rgba.png        vit_*.png skin/eye/mouth textures (copied)
Run after fetch_upstream.sh. Needs numpy + Pillow."""
import json, struct, os, shutil, subprocess, sys, numpy as np
from PIL import Image
H = os.path.dirname(os.path.abspath(__file__)); U = os.path.join(H, "upstream", "godot_project"); O = os.path.join(H, "out")
os.makedirs(O, exist_ok=True)
strip = os.path.join(H, "..", "..", "tools", "strip_glb_attrs.py")
def load(f):
    b = open(f, "rb").read(); ln = struct.unpack("<I", b[12:16])[0]; return json.loads(b[20:20 + ln]), b[20 + ln:]
def save(j, rest, out):
    js = json.dumps(j, separators=(",", ":")).encode(); js += b" " * ((4 - len(js) % 4) % 4)
    open(out, "wb").write(b"glTF" + struct.pack("<II", 2, 12 + 8 + len(js) + len(rest)) + struct.pack("<I", len(js)) + b"JSON" + js + rest)
# 1. body as-is, head with only UV0 (extra COLOR/TEXCOORD sets break UVs on Vivante)
shutil.copy(os.path.join(U, "vitruvian_body.glb"), O)
subprocess.run([sys.executable, strip, os.path.join(U, "vitruvian_head.glb"), os.path.join(O, "vitruvian_head_lite.glb"), "POSITION,NORMAL,TANGENT,TEXCOORD_0"], check=True)
# 2. brows: keep only the brow-card node of the legacy hair GLB
j, rest = load(os.path.join(U, "vitruvian_hair.glb"))
j["scenes"][0]["nodes"] = [i for i, n in enumerate(j["nodes"]) if "Brow" in n.get("name", "")]
save(j, rest, os.path.join(O, "brows_lite.glb"))
# 3. textures: hair diffuse+opacity -> RGBA 1K (kept for reference; hair cards do NOT run on GC7000UL), brow atlas -> dark RGBA
d = Image.open(os.path.join(U, "vit_hair_diffuse.png")).convert("RGB"); o = Image.open(os.path.join(U, "vit_hair_opacity.png")).convert("L")
h = d.copy(); h.putalpha(o); h.resize((1024, 1024), Image.LANCZOS).save(os.path.join(O, "hair_rgba.png"))
a = Image.open(os.path.join(U, "vit_hair_atlas.png")).convert("L"); bimg = Image.new("RGB", a.size, (28, 20, 14)); bimg.putalpha(a); bimg.save(os.path.join(O, "brow_rgba.png"))
for t in ["vit_face_bc", "vit_face_n", "vit_face_rough", "vit_body_bc", "vit_body_n", "vit_body_rough", "vit_mouth", "vit_sclera", "vit_iris", "vit_fabric_n"]:
    shutil.copy(os.path.join(U, t + ".png"), O)
# 4. scalp cap: a 2.5 mm shell over the scalp region of the face mesh = buzz cut (hair cards are too heavy for the board)
j, rest = load(os.path.join(O, "vitruvian_head_lite.glb"))
ln = struct.unpack("<I", rest[0:4])[0]; bin_ = rest[8:8 + ln]
def acc(i):
    a = j["accessors"][i]; bv = j["bufferViews"][a["bufferView"]]; off = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    ct = {5126: "<f4", 5123: "<u2", 5121: "<u1", 5125: "<u4"}[a["componentType"]]; n = {"VEC2": 2, "VEC3": 3, "VEC4": 4, "SCALAR": 1}[a["type"]]
    return np.frombuffer(bin_, dtype=ct, count=a["count"] * n, offset=off).reshape(a["count"], n).astype(np.float64 if "f" in ct else np.int64)
m = [m for m in j["meshes"] if m["name"] == "cm_vitruvian"][0]; p = m["primitives"][0]
P = acc(p["attributes"]["POSITION"]); N = acc(p["attributes"]["NORMAL"]); I = acc(p["indices"]).reshape(-1, 3)
top = P[:, 1].max(); y = P[:, 1]; z = P[:, 2]; x = P[:, 0]; front = z > 0.02
mask = ((~front) & (y > top - 0.20)) | (front & (y > top - 0.105 + 0.3 * np.clip(z - 0.02, 0, None) + 0.5 * np.abs(x) ** 2 * 4))
mask &= y > top - 0.20
tri = I[mask[I].all(axis=1)]; used = np.unique(tri); remap = {v: i for i, v in enumerate(used)}
V = (P[used] + N[used] * 0.0025).astype("<f4"); NN = N[used].astype("<f4"); T = np.vectorize(remap.get)(tri).astype("<u4")
data = V.tobytes() + NN.tobytes() + T.tobytes()
g = {"asset": {"version": "2.0"}, "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"name": "ScalpCap", "mesh": 0}],
     "meshes": [{"name": "ScalpCap", "primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1}, "indices": 2, "material": 0}]}], "materials": [{"name": "VitScalp"}],
     "buffers": [{"byteLength": len(data)}],
     "bufferViews": [{"buffer": 0, "byteOffset": 0, "byteLength": V.nbytes}, {"buffer": 0, "byteOffset": V.nbytes, "byteLength": NN.nbytes}, {"buffer": 0, "byteOffset": V.nbytes + NN.nbytes, "byteLength": T.nbytes}],
     "accessors": [{"bufferView": 0, "componentType": 5126, "count": len(V), "type": "VEC3", "min": V.min(0).tolist(), "max": V.max(0).tolist()},
                   {"bufferView": 1, "componentType": 5126, "count": len(NN), "type": "VEC3"}, {"bufferView": 2, "componentType": 5125, "count": T.size, "type": "SCALAR"}]}
js = json.dumps(g, separators=(",", ":")).encode(); js += b" " * ((4 - len(js) % 4) % 4); data += b"\0" * ((4 - len(data) % 4) % 4)
open(os.path.join(O, "scalp_cap.glb"), "wb").write(b"glTF" + struct.pack("<II", 2, 12 + 8 + len(js) + 8 + len(data)) + struct.pack("<I", len(js)) + b"JSON" + js + struct.pack("<I", len(data)) + b"BIN\0" + data)
print("scalp cap tris", len(tri)); print("out/:", sorted(os.listdir(O)))
