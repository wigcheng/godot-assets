#!/usr/bin/env python3
"""Print what is inside a GLB: meshes, vertex counts, attributes, blend shape names, materials, nodes, animations.
usage: glb_info.py file.glb"""
import json, struct, sys
b = open(sys.argv[1], "rb").read(); ln = struct.unpack("<I", b[12:16])[0]; j = json.loads(b[20:20 + ln])
print("nodes", len(j.get("nodes", [])), "skins", len(j.get("skins", [])), "animations", [a.get("name") for a in j.get("animations", [])])
for m in j["meshes"]:
    tn = m.get("extras", {}).get("targetNames", [])
    for p in m["primitives"]:
        print(" mesh", m["name"], "verts", j["accessors"][p["attributes"]["POSITION"]]["count"], "attrs", sorted(p["attributes"]),
              "material", j["materials"][p["material"]]["name"] if "material" in p else None, "targets", len(tn))
    if tn: print("  blend shapes:", tn)
