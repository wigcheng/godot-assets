extends Node
# Procedural sedan / police car, ~40 primitives, CC0 (ours). Replaces the 7-box car of city.gd.
#   const Car = preload("res://lib/vehicles/procar.gd")
#   var car := Car.build(parent, Color(0.85, 0.05, 0.08), false)   # returns Node3D facing -Z (front at -Z, like city.gd)
#   Car.drive(car, speed_mps, delta, braking: bool, drift: float)     # spins wheels, body roll, brake lights
#   Car.siren(car, t)                                                  # police: alternate red/blue bar + light
# Metadata is stored in car.set_meta(): wheels, tail material, bar materials, roll node.
static func mat(col: Color, rough := 0.5, metal := 0.0, emit := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = rough
	m.metallic = metal
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = emit
	return m

static func box(parent: Node3D, size: Vector3, p: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = p
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

static func prism(parent: Node3D, size: Vector3, p: Vector3, m: Material, rot := Vector3.ZERO, left_to_right := 0.5) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = size
	pm.left_to_right = left_to_right
	mi.mesh = pm
	mi.material_override = m
	mi.position = p
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi

static func build(parent: Node3D, col: Color, police: bool) -> Node3D:
	var car := Node3D.new()
	parent.add_child(car)
	var body := Node3D.new()          # everything that rolls/pitches
	car.add_child(body)
	var paint := mat(col, 0.28, 0.85)
	var dark := mat(Color(0.05, 0.05, 0.06), 0.6)
	var glass := mat(Color(0.08, 0.1, 0.14), 0.08, 0.3)
	var chrome := mat(Color(0.8, 0.8, 0.82), 0.2, 1.0)
	# lower body + hood + trunk
	box(body, Vector3(1.9, 0.5, 4.4), Vector3(0, 0.6, 0), paint)
	box(body, Vector3(1.86, 0.18, 1.5), Vector3(0, 0.94, -1.35), paint)                   # hood
	box(body, Vector3(1.86, 0.2, 1.1), Vector3(0, 0.95, 1.55), paint)                     # trunk
	# cabin: sloped windshield + rear glass as prisms, roof box, side glass inset
	box(body, Vector3(1.7, 0.5, 1.9), Vector3(0, 1.3, 0.15), paint)
	box(body, Vector3(1.72, 0.36, 1.6), Vector3(0, 1.28, 0.15), glass)                   # side windows (protrude 1 cm)
	prism(body, Vector3(1.7, 0.5, 0.9), Vector3(0, 1.3, -1.25), glass, Vector3(0, 0, 0), 1.0)   # windshield wedge
	prism(body, Vector3(1.7, 0.5, 0.7), Vector3(0, 1.3, 1.2), glass, Vector3(0, 0, 0), 0.0)     # rear glass wedge
	box(body, Vector3(1.72, 0.06, 1.95), Vector3(0, 1.58, 0.15), paint)                   # roof
	# bumpers, sills, grille, plates, mirrors
	box(body, Vector3(1.92, 0.22, 0.25), Vector3(0, 0.42, -2.25), dark)
	box(body, Vector3(1.92, 0.22, 0.25), Vector3(0, 0.42, 2.25), dark)
	box(body, Vector3(1.0, 0.18, 0.04), Vector3(0, 0.72, -2.21), dark)                     # grille
	box(body, Vector3(0.5, 0.12, 0.02), Vector3(0, 0.5, -2.39), mat(Color(0.95, 0.95, 0.9), 0.6))   # plates
	box(body, Vector3(0.5, 0.12, 0.02), Vector3(0, 0.5, 2.39), mat(Color(0.95, 0.95, 0.9), 0.6))
	for sx in [-1.0, 1.0]:
		box(body, Vector3(0.12, 0.1, 0.22), Vector3(sx * 1.0, 1.15, -0.75), paint)        # mirrors
		box(body, Vector3(0.1, 0.1, 0.1), Vector3(sx * 1.06, 1.15, -0.75), glass)
		box(body, Vector3(0.03, 0.08, 0.6), Vector3(sx * 0.95, 1.2, -0.3), chrome)         # door trim
		box(body, Vector3(0.02, 0.07, 0.6), Vector3(sx * 0.95, 1.2, 0.45), chrome)
	# wheel arches (dark cut-outs) + wheels with rims; wheels are stored for spinning
	var wheels := []
	var tyre := mat(Color(0.03, 0.03, 0.03), 0.9)
	for sx in [-1.0, 1.0]:
		for wz in [-1.4, 1.45]:
			box(body, Vector3(0.3, 0.6, 1.0), Vector3(sx * 0.9, 0.5, wz), dark)
			var w := Node3D.new()
			w.position = Vector3(sx * 0.95, 0.38, wz)
			car.add_child(w)
			var cm := CylinderMesh.new()
			cm.top_radius = 0.38
			cm.bottom_radius = 0.38
			cm.height = 0.26
			cm.radial_segments = 24
			var t := MeshInstance3D.new()
			t.mesh = cm
			t.material_override = tyre
			t.rotation.z = PI / 2.0
			w.add_child(t)
			var rm := CylinderMesh.new()
			rm.top_radius = 0.24
			rm.bottom_radius = 0.24
			rm.height = 0.28
			rm.radial_segments = 12
			var r := MeshInstance3D.new()
			r.mesh = rm
			r.material_override = chrome
			r.rotation.z = PI / 2.0
			w.add_child(r)
			for k in 5:   # spokes
				box(w, Vector3(0.04, 0.4, 0.06), Vector3(sx * 0.14, 0, 0), dark, Vector3(k * 36.0, 0, 0))
			wheels.append(w)
	# lights
	var head := mat(Color(1.0, 0.97, 0.9), 0.1, 0.0, 4.0)
	var tail := mat(Color(1.0, 0.08, 0.05), 0.2, 0.0, 2.0)
	var amber := mat(Color(1.0, 0.6, 0.1), 0.2, 0.0, 1.2)
	for sx in [-0.62, 0.62]:
		box(body, Vector3(0.5, 0.16, 0.04), Vector3(sx, 0.8, -2.21), head)
		box(body, Vector3(0.14, 0.1, 0.04), Vector3(sx * 1.45, 0.78, -2.2), amber)
		box(body, Vector3(0.55, 0.16, 0.04), Vector3(sx, 0.82, 2.21), tail)
	car.set_meta("tail", tail)
	car.set_meta("wheels", wheels)
	car.set_meta("body", body)
	if police:
		var white := mat(Color(0.93, 0.93, 0.95), 0.3, 0.6)
		box(body, Vector3(1.91, 0.3, 1.6), Vector3(0, 0.6, 0.0), mat(Color(0.03, 0.03, 0.05), 0.5))   # black door band
		box(body, Vector3(1.0, 0.1, 0.4), Vector3(0, 1.66, 0.1), dark)                       # bar base
		var br := mat(Color(1.0, 0.05, 0.05), 0.2, 0.0, 6.0)
		var bb := mat(Color(0.1, 0.3, 1.0), 0.2, 0.0, 6.0)
		box(body, Vector3(0.42, 0.14, 0.34), Vector3(-0.28, 1.72, 0.1), br)
		box(body, Vector3(0.42, 0.14, 0.34), Vector3(0.28, 1.72, 0.1), bb)
		car.set_meta("bar_r", br)
		car.set_meta("bar_b", bb)
	return car

static func drive(car: Node3D, speed: float, delta: float, braking: bool, drift := 0.0) -> void:
	for w in car.get_meta("wheels"):
		(w as Node3D).rotate_x(-speed * delta / 0.38)
	var body: Node3D = car.get_meta("body")
	body.rotation.z = -0.06 * drift                       # lean into the drift
	body.rotation.x = 0.02 if braking else -0.004 * speed / 28.0
	var tail: StandardMaterial3D = car.get_meta("tail")
	tail.emission_energy_multiplier = 5.0 if braking else 2.0

static func siren(car: Node3D, t: float) -> void:
	if not car.has_meta("bar_r"):
		return
	var on := fmod(t, 0.5) < 0.25
	(car.get_meta("bar_r") as StandardMaterial3D).emission_energy_multiplier = 8.0 if on else 0.3
	(car.get_meta("bar_b") as StandardMaterial3D).emission_energy_multiplier = 0.3 if on else 8.0
