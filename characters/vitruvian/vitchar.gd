extends Node3D
# Vitruvian CC0 digital human as a drop-in dancer: body GLB (Skeleton3D), head GLB on the Head bone,
# hair cards + brows on the same rig. Pose joints are the dream.gd pivot names (chest/head/lsh/lel/...)
# with the same Euler convention; they are mapped onto Mixamo bones through each bone's rest basis, so
# the old pose tables keep working. Face = native blend shapes (26, see shape names in the head GLB).
const BONE := {"hips": "Hips", "chest": "Spine", "head": "Head",
	"lsh": "LeftArm", "lel": "LeftForeArm", "rsh": "RightArm", "rel": "RightForeArm",
	"lhip": "LeftUpLeg", "lknee": "LeftLeg", "rhip": "RightUpLeg", "rknee": "RightLeg"}
var skel: Skeleton3D
var face: MeshInstance3D
var bs := {}
var bi := {}            # joint -> bone index
var fix := {}           # joint -> Quaternion that first brings the limb to hang straight down (A/T-pose rest)
var _texc := {}
# direction retarget: each pose joint = a bone and the child bone that marks the limb end
const END := {"chest": "Neck", "head": "HeadTop_End", "lsh": "LeftForeArm", "lel": "LeftHand", "rsh": "RightForeArm", "rel": "RightHand",
	"lhip": "LeftLeg", "lknee": "LeftFoot", "rhip": "RightLeg", "rknee": "RightFoot"}
var rest_dir := {}      # joint -> character-space rest direction of the limb
var rest_gq := []       # bone -> character-space rest rotation
var joint_of := {}      # bone -> joint name

func setup(c: Dictionary) -> void:
	# c: shirt, pants, shoes (Color), hair (bool)
	var body := _glb("res://vitruvian_body.glb")
	add_child(body)
	skel = _find(body, "Skeleton3D") as Skeleton3D
	var anim := _find(body, "AnimationPlayer") as AnimationPlayer
	if anim:
		anim.stop()
		anim.queue_free()
	for mi in _meshes(body):
		for s in mi.mesh.get_surface_count():
			match _matname(mi, s):
				"VitShirt": mi.set_surface_override_material(s, _cloth(c.get("shirt", Color(0.85, 0.85, 0.88))))
				"VitPants": mi.set_surface_override_material(s, _cloth(c.get("pants", Color(0.2, 0.22, 0.3))))
				"VitShoes": mi.set_surface_override_material(s, _flat(c.get("shoes", Color(0.08, 0.07, 0.07)), 0.5))
				_: mi.set_surface_override_material(s, _skin("res://vit_body_bc.png", "res://vit_body_n.png", "res://vit_body_rough.png"))
	for j in BONE:
		for i in skel.get_bone_count():
			if skel.get_bone_name(i).ends_with(BONE[j]):
				bi[j] = i
	# head + hair + brows ride the Head bone
	var att := BoneAttachment3D.new()
	skel.add_child(att)
	att.bone_idx = bi["head"]
	var rig := Node3D.new()
	att.add_child(rig)
	rig.global_transform = global_transform
	var head := _glb("res://vitruvian_head_lite.glb")
	rig.add_child(head)
	for mi in _meshes(head):
		for s in mi.mesh.get_surface_count():
			match _matname(mi, s):
				"VitSkin": mi.set_surface_override_material(s, _skin("res://vit_face_bc.png", "res://vit_face_n.png", "res://vit_face_rough.png"))
				"VitMouth": mi.set_surface_override_material(s, _tex_mat("res://vit_mouth.png", 0.6))
				"VitSclera": mi.set_surface_override_material(s, _sclera())
				"VitIris": mi.set_surface_override_material(s, _tex_mat("res://vit_iris.png", 0.55))
				"VitEyeBack": mi.set_surface_override_material(s, _pupil())
				"VitCornea2": mi.set_surface_override_material(s, _glass())
				"VitEyeshadow": mi.set_surface_override_material(s, _flat(Color(0.3, 0.16, 0.26, 0.0), 0.7, true))
				"VitTearline": mi.set_surface_override_material(s, _glass())
				"VitCaruncle": mi.set_surface_override_material(s, _flat(Color(0.7, 0.35, 0.35), 0.4))
				_: pass
		if mi.mesh.get_blend_shape_count() > 0 and face == null:
			face = mi
			for i in mi.mesh.get_blend_shape_count():
				bs[String(mi.mesh.get_blend_shape_name(i))] = i
	if c.get("hair", true):
		var hc := _glb("res://hair_cards_lite.glb")
		rig.add_child(hc)
		for mi in _meshes(hc):
			mi.material_override = _card("res://hair_rgba.png", 0.55)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# buzz cut: a thin dark shell over the scalp region of the head mesh (hair cards are too heavy for GC7000UL)
	if c.get("cap", true):
		var cap := _glb("res://scalp_cap.glb")
		rig.add_child(cap)
		for mi in _meshes(cap):
			mi.material_override = _flat(c.get("hair_color", Color(0.09, 0.07, 0.06)), 0.75)
	if c.get("brows", true):
		var br := _glb("res://brows_lite.glb")
		rig.add_child(br)
		for mi in _meshes(br):
			mi.material_override = _card("res://brow_rgba.png", 0.7, 0.22)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# limbs: rotation that takes the rest limb direction to straight down, so pose tables that assume
	# hanging arms (dream.gd) apply unchanged whether the GLB rests in A- or T-pose
	for pair in [["lsh", "lel"], ["rsh", "rel"], ["lhip", "lknee"], ["rhip", "rknee"]]:
		var a: Vector3 = _rest_global(bi[pair[0]]).origin
		var b: Vector3 = _rest_global(bi[pair[1]]).origin
		fix[pair[0]] = Quaternion((b - a).normalized(), Vector3.DOWN)
	for j in ["lel", "rel", "lknee", "rknee"]:
		fix[j] = Quaternion.IDENTITY   # child limb already hangs once the parent is fixed
	for b in skel.get_bone_count():
		rest_gq.append(_rest_global(b).basis.get_rotation_quaternion())
	for j in END:
		var e := -1
		for i in skel.get_bone_count():
			if skel.get_bone_name(i).ends_with(END[j]):
				e = i
		if bi.has(j) and e >= 0:
			rest_dir[j] = (_rest_global(e).origin - _rest_global(bi[j]).origin).normalized()
			joint_of[bi[j]] = j
	print("VitChar: bones=%d joints=%s shapes=%d" % [skel.get_bone_count(), bi.keys(), bs.size()])

func _rest_global(b: int) -> Transform3D:
	var t := skel.get_bone_rest(b)
	var p := skel.get_bone_parent(b)
	while p >= 0:
		t = skel.get_bone_rest(p) * t
		p = skel.get_bone_parent(p)
	return t

# joint rotation in the dream.gd convention (degrees, Node3D Euler order) → bone pose
func set_joint(j: String, euler_deg: Vector3) -> void:
	if not bi.has(j):
		return
	var b: int = bi[j]
	var fq: Quaternion = fix.get(j, Quaternion.IDENTITY)
	var q: Quaternion = Quaternion.from_euler(euler_deg * (PI / 180.0)) * fq
	var p := skel.get_bone_parent(b)
	var pg: Quaternion = _rest_global(p).basis.get_rotation_quaternion() if p >= 0 else Quaternion.IDENTITY
	var local_extra: Quaternion = pg.inverse() * q * pg
	skel.set_bone_pose_rotation(b, local_extra * skel.get_bone_rest(b).basis.get_rotation_quaternion())

# mocap drive: dirs = joint -> wanted limb direction in character space (unit Vector3 or Array[3]).
# Bones are solved top-down: the wanted global rotation is the minimal rotation taking the rest limb
# direction to the target, applied to the rest global rotation; the local pose is derived from the
# parent's already-solved global rotation, so limb lengths are kept and untracked bones stay at rest.
func apply_dirs(dirs: Dictionary) -> void:
	var gq := []
	gq.resize(skel.get_bone_count())
	for b in skel.get_bone_count():
		var p := skel.get_bone_parent(b)
		var pq: Quaternion = gq[p] if p >= 0 else Quaternion.IDENTITY
		var lq: Quaternion = skel.get_bone_rest(b).basis.get_rotation_quaternion()
		var j: String = joint_of.get(b, "")
		if j != "" and dirs.has(j):
			var dv = dirs[j]
			var d := Vector3(dv[0], dv[1], dv[2]).normalized()
			var r := Quaternion(rest_dir[j], d)
			lq = pq.inverse() * (r * rest_gq[b])
		gq[b] = pq * lq
		skel.set_bone_pose_rotation(b, lq)

func shape(n: String, v: float) -> void:
	if face and bs.has(n):
		face.set_blend_shape_value(bs[n], v)

# ---- loading / materials (runtime, no editor import) ----
func _glb(p: String) -> Node:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	assert(doc.append_from_file(p, st) == OK, "glb load failed: " + p)
	return doc.generate_scene(st)

func _find(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r:
			return r
	return null

func _meshes(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out += _meshes(c)
	return out

func _matname(mi: MeshInstance3D, s: int) -> String:
	var m := mi.mesh.surface_get_material(s)
	return (m.resource_name if m else "").split(".")[0]

func _tex(p: String) -> ImageTexture:
	if not _texc.has(p):
		var img := Image.load_from_file(p)
		img.generate_mipmaps()
		_texc[p] = ImageTexture.create_from_image(img)
	return _texc[p]

func _skin(bc: String, n: String, r: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex(bc)
	m.normal_enabled = true
	m.normal_texture = _tex(n)
	m.normal_scale = 0.8
	m.roughness_texture = _tex(r)
	m.roughness = 1.0
	m.metallic_specular = 0.4
	m.rim_enabled = true
	m.rim = 0.2
	m.rim_tint = 0.7
	return m

func _tex_mat(p: String, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _tex(p)
	m.roughness = rough
	return m

func _flat(c: Color, rough: float, transparent := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

func _cloth(c: Color) -> StandardMaterial3D:
	var m := _flat(c, 0.95)
	m.normal_enabled = true
	m.normal_texture = _tex("res://vit_fabric_n.png")
	m.uv1_scale = Vector3(6, 6, 6)
	return m

func _sclera() -> StandardMaterial3D:
	var m := _tex_mat("res://vit_sclera.png", 0.18)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.albedo_color = Color(0.96, 0.94, 0.93)
	return m

func _pupil() -> StandardMaterial3D:
	var m := _flat(Color(0.008, 0.007, 0.008), 1.0)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _card(p: String, rough: float, cut := 0.4) -> StandardMaterial3D:
	var m := _tex_mat(p, rough)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = cut
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _glass() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.0)
	m.roughness = 0.03
	m.metallic_specular = 1.0
	return m
