# Chinese signboards
`python3 gen_signs.py` → `out/v_NN.png` (256×1024 vertical) and `out/h_NN.png` (1024×256). Edit the V / H lists for new text.
Use as emissive quads (MultiMesh per texture):
```gdshader-free
var m := StandardMaterial3D.new()
m.albedo_texture = tex(p); m.emission_enabled = true; m.emission_texture = tex(p); m.emission = Color(1,1,1)
m.emission_energy_multiplier = 0.5          # 1.6 + glow blows out to white; keep ≤ 0.6 and set env.glow_hdr_threshold = 1.3
m.cull_mode = BaseMaterial3D.CULL_DISABLED  # readable from both sides
```
Hanging sign: QuadMesh scaled (1.2, 4.2) perpendicular to the facade, 1.0 m out, 5–8.5 m up. Facade sign: (5.4, 1.35) at 4.35 m.
