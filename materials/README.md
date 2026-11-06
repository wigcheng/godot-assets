# Materials — CC0 photo textures (ambientCG, 1K JPG)
Files: `<Name>_color.jpg`, `<Name>_rough.jpg`. Concrete034 / PaintedPlaster017 = walls, Tiles074 = sidewalk, Asphalt012 = road (+ wet patches from its roughness map), MetalPlates006 = roll-down shutters.
```gdscript
func tex(p: String) -> ImageTexture:
	var img := Image.load_from_file(p); img.generate_mipmaps(); return ImageTexture.create_from_image(img)
var m := StandardMaterial3D.new()
m.albedo_texture = tex("res://lib/materials/ambientcg/Concrete034_color.jpg")
m.roughness_texture = tex("res://lib/materials/ambientcg/Concrete034_rough.jpg")
m.uv1_scale = Vector3(2, 2, 2)
```
In custom shaders declare `uniform sampler2D wall : source_color, filter_linear_mipmap, repeat_enable;` and bind with `set_shader_parameter`.
Verified: building/road shaders with 2–3 samplers run at full speed; world-space UV `(h, y) / 2.5` reads as ~2.5 m tiles.
