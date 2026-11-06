extends Node
# Parked scooter built from primitives (7 meshes). CC0 (our own). Verified on i.MX8MP: 30+ instances cost nothing visible.
# usage:  const Props = preload("res://lib/props/scooter.gd")
#         Props.build(self, Vector3(x, 0, z), yaw_radians, Color(0.8, 0.1, 0.1))

static func build(parent: Node3D, p: Vector3, yaw: float, col: Color) -> void:
	var n := Node3D.new()
	n.position = p
	n.rotation.y = yaw
	parent.add_child(n)
	box(n, Vector3(0.42, 0.32, 0.9), Vector3(0, 0.55, 0.15), mat(col))
	box(n, Vector3(0.44, 0.1, 0.6), Vector3(0, 0.74, 0.25), mat(Color(0.05, 0.05, 0.06)))
	box(n, Vector3(0.36, 0.5, 0.25), Vector3(0, 0.6, -0.55), mat(col))
	box(n, Vector3(0.5, 0.04, 0.05), Vector3(0, 0.95, -0.62), mat(Color(0.1, 0.1, 0.1)))
	box(n, Vector3(0.15, 0.08, 0.04), Vector3(0, 0.78, -0.69), mat(Color(1.0, 0.95, 0.8), 2.5))
	var wm := mat(Color(0.03, 0.03, 0.03))
	for wz in [-0.62, 0.62]:
		var w := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.22
		cm.bottom_radius = 0.22
		cm.height = 0.1
		w.mesh = cm
		w.material_override = wm
		w.position = Vector3(0, 0.22, wz)
		w.rotation.z = PI / 2.0
		n.add_child(w)

# Street dressing along the chase route (the z road at x=0, then the x road at z=TURN_Z):
# hanging vertical signboards, facade signs, shutters / lit shopfronts, awnings, parked scooters, wires.

static func mat(col: Color, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.35
	m.metallic = 0.4
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit
	return m


static func box(parent: Node3D, size: Vector3, p: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	parent.add_child(mi)

