# godot-assets — board-verified asset library for Godot 4.7 videos on i.MX8MP

Read this file first. It is written for an AI agent (e.g. Gemma 4 on the test board) as much as for people:
every asset has its own short README with copy-paste GDScript, and `REGISTRY.json` holds the measured facts.
Do not guess what runs on the GPU — look it up in the registry; if it is not there, it has not been tested.

## 1. Hard constraints of the target (never violate)
| Item | Fact |
|---|---|
| Engine | Godot 4.7.2 official arm64 binary on the board; projects run from source, **no editor import step** |
| Renderer | Vulkan **Mobile** (forced: Vivante GC7000UL exposes 16 textures per stage) |
| Loading | GLB via `GLTFDocument.append_from_file` + `generate_scene`; textures via `Image.load_from_file` + `ImageTexture.create_from_image` (then `generate_mipmaps()`) |
| GLB vertex attributes | keep only POSITION / NORMAL / TANGENT / TEXCOORD_0 (+ JOINTS_0 / WEIGHTS_0 for skinned). Extra COLOR_n / TEXCOORD_n sets corrupt the UVs → run `tools/strip_glb_attrs.py` |
| Transparency | `TRANSPARENCY_ALPHA_SCISSOR` works; sorted alpha blending is unreliable; **dense alpha card meshes (hair) never render a frame** |
| Materials | `StandardMaterial3D` only, ≤ 4 textures each; no SSS, no custom shaders with > 8 varyings |
| Budget (1080p) | one skinned 40k-vert character + props ≈ 7.5 FPS; videos are recorded with Movie Maker (`--fixed-fps 30 --write-movie`) so FPS only affects recording time |
| Vertex-heavy is fine, pixel-heavy is not | MultiMesh thousands of boxes: free. Full-screen procedural noise: 7 FPS. Bake noise to textures. |
| GDScript gotchas | `var x := a if c else b` with mixed types → Parse error (type it); do not name a method `_set`/`_get`; property is `metallic_specular` not `specular` |

## 2. Layout
```
characters/vitruvian/   CC0 realistic human: body (Mixamo rig, 6 clips), head (26 blend shapes), buzz-cut cap, brows; VitChar.gd driver
props/                  procedural props (scooter, …) as static GDScript builders
materials/ambientcg/    CC0 1K photo textures + how to bind them
signs/                  Chinese signboard generator (Noto Sans CJK TC) → emissive quads
shaders/                building / road / sky-apartment / post-process shaders that compile on Vivante
audio/                  numpy soundtrack + SFX generators (copyright-free)
mocap/                  pose data extracted from reference clips (joint directions per frame) for VitChar.apply_dirs()
tools/                  strip_glb_attrs.py, glb_info.py, make_uvgrid.py, extract_pose.py, pose_to_mocap.py, deploy.sh
board/                  playback loop, service file, screenshot/record script templates
REGISTRY.json / .md     every asset: license, size, measured FPS, known traps
LICENSES.md             where everything came from and what it allows
```

## 3. How to use an asset in a project
1. Symlink the library into the project: `ln -s ~/workspace/godot-assets <project>/lib` (Godot only sees `res://`, the symlink makes it `res://lib/...`).
2. Read `<asset>/README.md`, copy its snippet.
3. Deploy with `tools/deploy.sh <project>` (expands symlinks), take stills with a script like `board/shots-example.sh`, look at the PNG. Only a PNG from the board counts as verified.
4. Add a row to `REGISTRY.json` with the measured numbers.

## 4. Adding a new asset (checklist)
- License row in `LICENSES.md` first. CC0 / CC-BY / MIT only; CC-BY → credit line recorded. No real-brand designs.
- `tools/glb_info.py file.glb` → if attributes other than the allowed set exist, `tools/strip_glb_attrs.py`.
- Triangles ≤ 30k per character, ≤ 10k per prop; textures ≤ 2048, PNG/JPG.
- Prove it on the board (one still), then register it.
