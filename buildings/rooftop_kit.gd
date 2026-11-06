extends Node
# Taiwan rooftop / mid-rise facade kit: everything is primitives + CC0 ambientCG textures, so it loads at runtime
# with no editor import. Static builders; call with the scene root as `parent`.
#   const Kit = preload("res://lib/buildings/rooftop_kit.gd")
#   Kit.water_tank(self, Vector3(4, 0, -6))              # stainless tank on a steel frame (1.2 m dia)
#   Kit.antenna(self, Vector3(-5, 0, 3))                 # TV antenna mast
#   Kit.ac_unit(self, Vector3(2, 0.33, 5), 0.0)          # outdoor unit with pipes
#   Kit.metal_shed(self, Vector3(6, 0, -5), Vector3(4, 2.6, 3))   # 鐵皮加蓋 with a gable roof
#   Kit.parapet(self, 26.0, 1.0)                         # tiled parapet around a square roof of that size
#   Kit.tree(self, Vector3(-9, 0, 6), 5.0)               # trunk + leaf clusters
#   Kit.facade_dressing(self, xforms)                    # balconies + railings on MultiMesh box buildings (Transform3D list)
# Verified on i.MX8MP 2026-11-06 (dream-wings rooftop): all of the above together ≈ no FPS change vs bare boxes.
const TEX := "res://lib/materials/ambientcg/"
static var _texc := {}

static func tex(p: String) -> ImageTexture:
	if not _texc.has(p):
		var img := Image.load_from_file(p)
		img.generate_mipmaps()
		_texc[p] = ImageTexture.create_from_image(img)
	return _texc[p]

static func mat(col: Color, rough := 0.7, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	return m

static func tmat(name: String, scale := 1.0, tint := Color(1, 1, 1), rough := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex(TEX + name + "_color.jpg")
	m.albedo_color = tint
	m.roughness_texture = tex(TEX + name + "_rough.jpg")
	m.roughness = rough
	m.uv1_scale = Vector3(scale, scale, scale)
	return m

static func mesh(parent: Node3D, me: Mesh, p: Vector3, m: Material, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = me
	mi.material_override = m
	mi.position = p
	mi.rotation_degrees = rot
	mi.scale = scl
	parent.add_child(mi)
	return mi

static func box(parent: Node3D, size: Vector3, p: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return mesh(parent, bm, p, m, rot)

static func cyl(parent: Node3D, r: float, h: float, p: Vector3, m: Material, rot := Vector3.ZERO, r2 := -1.0) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r if r2 < 0.0 else r2
	cm.height = h
	cm.radial_segments = 24
	return mesh(parent, cm, p, m, rot)

static func water_tank(parent: Node3D, p: Vector3) -> void:
	var steel := mat(Color(0.75, 0.76, 0.78), 0.28, 0.9)
	var frame := mat(Color(0.25, 0.26, 0.28), 0.6, 0.6)
	for sx in [-0.45, 0.45]:
		for sz in [-0.45, 0.45]:
			box(parent, Vector3(0.06, 0.9, 0.06), p + Vector3(sx, 0.45, sz), frame)
	box(parent, Vector3(1.1, 0.05, 1.1), p + Vector3(0, 0.9, 0), frame)
	cyl(parent, 0.6, 1.5, p + Vector3(0, 1.68, 0), steel)
	cyl(parent, 0.62, 0.12, p + Vector3(0, 2.46, 0), steel, Vector3.ZERO, 0.45)
	cyl(parent, 0.02, 1.0, p + Vector3(0.5, 0.45, 0.5), steel)   # feed pipe

static func antenna(parent: Node3D, p: Vector3) -> void:
	var m := mat(Color(0.5, 0.5, 0.52), 0.5, 0.8)
	cyl(parent, 0.02, 4.0, p + Vector3(0, 2.0, 0), m)
	for i in 5:
		var w := 0.9 - i * 0.12
		box(parent, Vector3(w, 0.015, 0.015), p + Vector3(0, 2.4 + i * 0.3, 0), m)
	box(parent, Vector3(0.015, 0.015, 1.2), p + Vector3(0, 2.4, 0), m)
	for sx in [-0.35, 0.35]:
		box(parent, Vector3(0.03, 1.0, 0.03), p + Vector3(sx, 0.5, 0), m, Vector3(0, 0, sx * 40.0))

static func ac_unit(parent: Node3D, p: Vector3, yaw := 0.0) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = yaw
	parent.add_child(n)
	box(n, Vector3(0.8, 0.62, 0.32), Vector3.ZERO, mat(Color(0.9, 0.9, 0.88), 0.6))
	var fan := CylinderMesh.new()
	fan.top_radius = 0.24
	fan.bottom_radius = 0.24
	fan.height = 0.03
	mesh(n, fan, Vector3(-0.12, 0.0, -0.17), mat(Color(0.3, 0.31, 0.33), 0.5), Vector3(90, 0, 0))
	box(n, Vector3(0.9, 0.04, 0.4), Vector3(0, -0.33, 0), mat(Color(0.35, 0.35, 0.36), 0.5, 0.5))   # stand
	var pipe := mat(Color(0.85, 0.85, 0.8), 0.7)
	cyl(n, 0.02, 0.6, Vector3(0.44, -0.1, 0.1), pipe, Vector3(0, 0, 90))

static func metal_shed(parent: Node3D, p: Vector3, size: Vector3) -> void:
	var wall := tmat("MetalPlates006", 0.8, Color(0.55, 0.6, 0.66), 0.5)
	box(parent, Vector3(size.x, size.y, size.z), p + Vector3(0, size.y / 2.0, 0), wall)
	var roofm := mat(Color(0.35, 0.4, 0.5), 0.55, 0.4)
	var prism := PrismMesh.new()
	prism.size = Vector3(size.x + 0.4, 0.8, size.z + 0.4)
	mesh(parent, prism, p + Vector3(0, size.y + 0.4, 0), roofm)
	box(parent, Vector3(0.9, 1.9, 0.04), p + Vector3(0, 0.95, size.z / 2.0 + 0.02), mat(Color(0.3, 0.32, 0.35), 0.5))

static func parapet(parent: Node3D, roof: float, h: float) -> void:
	var tile := tmat("Tiles074", 1.2, Color(0.85, 0.82, 0.78))
	var cap := mat(Color(0.8, 0.8, 0.78), 0.7)
	var e := roof / 2.0
	for s in [[Vector3(0, h / 2.0, e), Vector3(roof, h, 0.3)], [Vector3(0, h / 2.0, -e), Vector3(roof, h, 0.3)], [Vector3(e, h / 2.0, 0), Vector3(0.3, h, roof)], [Vector3(-e, h / 2.0, 0), Vector3(0.3, h, roof)]]:
		box(parent, s[1], s[0], tile)
		box(parent, s[1] + Vector3(0.1, -h + 0.08, 0.1), s[0] + Vector3(0, h / 2.0, 0), cap)

static func tree(parent: Node3D, p: Vector3, h: float) -> void:
	cyl(parent, 0.12, h * 0.5, p + Vector3(0, h * 0.25, 0), mat(Color(0.3, 0.22, 0.15), 0.9), Vector3.ZERO, 0.18)
	var leaf := mat(Color(0.16, 0.34, 0.14), 0.9)
	var sm := SphereMesh.new()
	sm.radius = h * 0.22
	sm.height = h * 0.44
	sm.radial_segments = 20
	sm.rings = 10
	for o in [Vector3(0, h * 0.62, 0), Vector3(h * 0.16, h * 0.5, h * 0.08), Vector3(-h * 0.14, h * 0.52, -h * 0.1), Vector3(0.02, h * 0.78, -h * 0.05), Vector3(h * 0.05, h * 0.45, -h * 0.17)]:
		mesh(parent, sm, p + o, leaf, Vector3.ZERO, Vector3(1.0, 0.85, 1.0))

# balconies + railings for box buildings given as MultiMesh transforms (scale = size, origin = centre).
# Faces toward the origin get a slab per floor (3.0 m), with a railing; cheap because it is two MultiMeshes.
static func facade_dressing(parent: Node3D, xforms: Array, floor_h := 3.0) -> void:
	var slabs := []
	var rails := []
	for t in xforms:
		var tt: Transform3D = t
		var sz := tt.basis.get_scale()
		var c := tt.origin
		var floors := int(sz.y / floor_h)
		if floors < 2:
			continue
		# which side faces the origin: pick the axis with the larger |c| component
		var face_x := absf(c.x) > absf(c.z)
		var sgn := -signf(c.x) if face_x else -signf(c.z)
		for k in range(1, floors):
			var y := c.y - sz.y / 2.0 + k * floor_h
			var w := (sz.z if face_x else sz.x) * 0.5
			var pos := c + (Vector3(sgn * (sz.x / 2.0 + 0.6), 0, 0) if face_x else Vector3(0, 0, sgn * (sz.z / 2.0 + 0.6)))
			pos.y = y
			var b := Basis(Vector3.UP, PI / 2.0 if face_x else 0.0)
			slabs.append(Transform3D(b * Basis.from_scale(Vector3(w, 0.14, 1.2)), pos))
			rails.append(Transform3D(b * Basis.from_scale(Vector3(w, 1.0, 0.06)), pos + (Vector3(sgn * 0.57, 0.55, 0) if face_x else Vector3(0, 0.55, sgn * 0.57))))
	_mm(parent, BoxMesh.new(), slabs, mat(Color(0.78, 0.76, 0.72), 0.8))
	var rm := mat(Color(0.2, 0.22, 0.25), 0.4, 0.6)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color.a = 0.55
	_mm(parent, BoxMesh.new(), rails, rm)

static func _mm(parent: Node3D, me: Mesh, xforms: Array, m: Material) -> void:
	if xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = me
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = m
	parent.add_child(mmi)
