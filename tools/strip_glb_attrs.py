#!/usr/bin/env python3
"""Keep only the vertex attributes the i.MX8MP (Vivante GC7000UL) path can use.
Extra COLOR_n / TEXCOORD_n sets make the GPU read the wrong UV (face texture lands in the wrong place).
usage: strip_glb_attrs.py in.glb out.glb [KEEP,LIST]   default keep: POSITION,NORMAL,TANGENT,TEXCOORD_0,JOINTS_0,WEIGHTS_0"""
import json, struct, sys
src, dst = sys.argv[1:3]
keep = set((sys.argv[3] if len(sys.argv) > 3 else "POSITION,NORMAL,TANGENT,TEXCOORD_0,JOINTS_0,WEIGHTS_0").split(","))
b = open(src, "rb").read(); ln = struct.unpack("<I", b[12:16])[0]; j = json.loads(b[20:20 + ln]); rest = b[20 + ln:]
dropped = set()
for m in j["meshes"]:
    for p in m["primitives"]:
        for k in list(p["attributes"]):
            if k not in keep: dropped.add(k); del p["attributes"][k]
        for t in p.get("targets", []):
            for k in list(t):
                if k not in keep: del t[k]
js = json.dumps(j, separators=(",", ":")).encode(); js += b" " * ((4 - len(js) % 4) % 4)
open(dst, "wb").write(b"glTF" + struct.pack("<II", 2, 12 + 8 + len(js) + len(rest)) + struct.pack("<I", len(js)) + b"JSON" + js + rest)
print("dropped", sorted(dropped), "->", dst)
