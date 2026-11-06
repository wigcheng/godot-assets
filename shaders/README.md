# Shaders (all compile and run on Vivante GC7000UL, Mobile renderer)
| File | Use | Samplers | Note |
|---|---|---|---|
| building.gdshader | MultiMesh box facades: 2 wall textures picked per instance, window grid + random lit windows | 2 | instance COLOR.rgb = tint, COLOR.a = seed |
| road.gdshader | 54 m street grid, lane marks, wet asphalt | 3 | roads at multiples of 54 m, half-width 7 m, sidewalk to 9.5 m |
| apt.gdshader | far apartment blocks (dream scene) | 0 | |
| post.gdshader | full-screen whip-pan blur | 0 | `blur` uniform 0..1 |
| story/raid/race/aurora*.gdshader | earlier portfolio scenes | — | aurora: bake noise to NoiseTexture2D, procedural fbm is 7 FPS |
Limit: ≤ 16 samplers incl. Godot's own, ≤ 16 varyings (spatial shaders: do not add custom varyings, derive from INV_VIEW_MATRIX in fragment).
