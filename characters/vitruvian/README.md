# Vitruvian — CC0 realistic digital human (board-verified 2026-11-06)

Upstream: https://github.com/ibrews/VitruvianGodot @ 8b643c3 (character CC0, code MIT). Mixamo clips inside the body GLB.
Build the board files once: `./fetch_upstream.sh && python3 make_assets.py` → `out/` (git-ignored, byte-reproducible).

| File (out/) | What | Verified |
|---|---|---|
| vitruvian_body.glb | 52-bone Mixamo rig, 3 meshes (body 18k verts, shirt, pants), clips HappyIdle/Idle/Sway/Turn/Walk/Wave | ✅ |
| vitruvian_head_lite.glb | head 17k verts, **26 blend shapes**, eyes, mouth; UV0 only | ✅ blend shapes compute correctly on Vivante |
| scalp_cap.glb | 4.8k-tri shell = buzz cut | ✅ |
| brows_lite.glb | eyebrow cards | ✅ with alpha scissor 0.22 |
| hair_rgba.png (+ upstream hairtool_cards.glb) | hair cards | ❌ **never renders a frame on GC7000UL** — do not use |
| vit_*.png | 2K skin / eye / mouth / fabric textures | ✅ |

Blend shape names: Jaw_Lower, Mouth_Large_Opened, Lips_Up_Funnel, Lips_Up_Corner_Wide_Left/Right, Happy, Sad, Angry, Scared, Disgusted,
Thinking, Kiss, Smile_Lips_Closed, Eyebrows_Raised_Left/Right, Eyebrows_Frown_Left/Right, Eyes_Closed_Max, Eyes_Opened_Max_Left/Right,
Eyes_Squint, visemes aa_02, ow_08, p_b_m_21, f_v_18, ey_eh_uh_04.

## Use
Copy `out/*` and `vitchar.gd` into the project (or symlink `lib/` and use `res://lib/characters/vitruvian/...` paths inside vitchar.gd).
```gdscript
const VitChar = preload("res://vitchar.gd")
var ch := VitChar.new()
add_child(ch)
ch.setup({"shirt": Color(0.9, 0.9, 0.9), "pants": Color(0.4, 0.5, 0.7), "shoes": Color(0.1, 0.1, 0.1), "cap": true, "brows": true, "hair": false})
# pose A: the dream.gd joint convention (degrees; joints chest head lsh lel rsh rel lhip lknee rhip rknee hips)
ch.set_joint("lsh", Vector3(-10, 0, 125))
# pose B: motion capture (see ../../mocap/README.md)
ch.apply_dirs(frame["dirs"])
# face
ch.shape("Happy", 0.6); ch.shape("Eyes_Closed_Max", 1.0)
```
Measured: 1080p 7.5 FPS with the rooftop scene; load ≈ 4 s per character; two characters fine (only one visible at a time).
Lighting that looks right: key SpotLight 3.0 warm, fill Omni 0.7 on the camera, rim 2.0; `rim_enabled` on the skin fakes the missing SSS.
