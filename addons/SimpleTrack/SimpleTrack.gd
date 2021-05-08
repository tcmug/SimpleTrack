extends MeshInstance
tool
class_name SimpleTrack

export var segment_length: float = 0.5
export var width: float = 2
export var tarmac1: Color
export var tarmac2: Color
export var side1: Color
export var side2: Color
export var rebuild: bool setget rebuild_track
export var physics_material: PhysicsMaterial
export var curve: Curve3D

func _ready():
	rebuild_track(true)

func rebuild_track(_b):

	if !curve:
		print("No curve data, please create it first!")
	var sz := width / 2
	var st := SurfaceTool.new()
	var up := Vector3(0, 1, 0)
	
	if curve.get_point_count() > 3:
		
		var last = curve.get_point_count() - 1
		var a = curve.get_point_position(0)
		var b = curve.get_point_position(last)

		curve.set_point_position(last, curve.get_point_position(0))
		curve.set_point_tilt(last, curve.get_point_tilt(0))
		curve.set_point_in(last, curve.get_point_in(0))
		curve.set_point_out(last, curve.get_point_out(0))
#
	curve.bake_interval = width / 5

	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var colors = [tarmac1, tarmac2]
	var side = [side1, side2]

	var curves = curve.get_baked_points()
	var tilts = curve.get_baked_tilts()
	
	if curves.empty():
		print("No points on curve.")
		return
	
	var origin = curves[0]
	var tilt = tilts[0]
	var next = curves[1]
	
	var start_origin = origin
	var start_tilt = tilt
	
	# Remove starting point
	curves.remove(1)
	tilts.remove(1)

	# Calculate starting point with bank/tilt
	var dir: Vector3 = (next - origin).normalized()
	var right := dir.cross(up).normalized()
	var a: Vector3 = origin + (right.rotated(dir, tilt) * sz)
	var b: Vector3 = origin + (right.rotated(dir, tilt) * -sz)
	var c := Vector3(0, 0, 0)
	var d := Vector3(0, 0, 0)
	
	var start_a = a
	var start_b = b

	var x = 0

	for point_index in range(1, curves.size()):
		
		x += 1
		var i = x / 5
		
		var point: Vector3
		if point_index == curves.size() - 1:
			point = start_origin
			tilt = start_tilt
			c = start_a
			d = start_b
		else:
			point = curves[point_index]
			tilt = tilts[point_index]
			next = point
			if next.distance_to(origin) == 0:
				print_debug("Same distance")

			dir = (next - origin).normalized()
			right = dir.cross(up).normalized()
			c = next + (right * sz).rotated(dir, tilt)
			d = next + (right * -sz).rotated(dir, tilt)
		
		origin = next
		var quads = subdivide([
			a, b, c, d
		], 1)
		while !quads.empty():
			var aa = quads.pop_front()
			var bb = quads.pop_front()
			var cc = quads.pop_front()
			var dd = quads.pop_front()
			st.add_color(colors[i % 2])
			st.add_uv(Vector2(0, 0))
			st.add_vertex(aa)
			st.add_uv(Vector2(1, 0))
			st.add_vertex(bb)
			st.add_uv(Vector2(0, 1))
			st.add_vertex(cc)

			st.add_color(colors[i % 2])
			st.add_uv(Vector2(0, 1))
			st.add_vertex(cc)
			st.add_uv(Vector2(1, 0))
			st.add_vertex(bb)
			st.add_uv(Vector2(1, 1))
			st.add_vertex(dd)

		st.add_color(side[i % 2])
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(a - Vector3(0, a.y, 0))
		st.add_color(side[i % 2])
		st.add_vertex(a - Vector3(0, a.y, 0))
		st.add_vertex(c)
		st.add_vertex(c - Vector3(0, c.y, 0))

		st.add_vertex(d)
		st.add_vertex(b)
		st.add_vertex(d - Vector3(0, d.y, 0))
		st.add_color(side[i % 2])
		st.add_vertex(d - Vector3(0, d.y, 0))
		st.add_vertex(b)
		st.add_vertex(b - Vector3(0, b.y, 0))
		
		a = c
		b = d 

	st.generate_normals()
	st.generate_tangents()

	mesh = st.commit()
	
	generate_collision_body()
	var sb = get_child(get_child_count()-1) as StaticBody
	sb.physics_material_override = physics_material
	
func generate_collision_body():
	var body := StaticBody.new()
	var polygons := ConcavePolygonShape.new()
	var shape := CollisionShape.new()
	body.add_child(shape)
	polygons.set_faces(mesh.get_faces())
	shape.shape = polygons
	add_child(body)

func subdivide(quads, level):
	quads = subdivide_once(quads)
	quads = subdivide_once(quads)
	for i in range(level):
		quads = subdivide_once(quads)
		quads = subdivide_once_b(quads)
	return quads

func subdivide_once(quads):
	var divided = []
	while !quads.empty():
		var a = quads.pop_front()
		var b = quads.pop_front()
		var c = quads.pop_front()
		var d = quads.pop_front()
		
		var ab = a + ((b - a) * 0.5)
		var cd = c + ((d - c) * 0.5)

		divided.push_back(a)
		divided.push_back(ab)
		divided.push_back(c)
		divided.push_back(cd)
		
		divided.push_back(ab)
		divided.push_back(b)
		divided.push_back(cd)
		divided.push_back(d)
	return divided

func subdivide_once_b(quads):
	var divided = []
	while !quads.empty():
		var c = quads.pop_front()
		var a = quads.pop_front()
		var d = quads.pop_front()
		var b = quads.pop_front()
		
		# a b 
		# c d
		
		var ab = a + ((b - a) * 0.5)
		var cd = c + ((d - c) * 0.5)

		divided.push_back(a)
		divided.push_back(ab)
		divided.push_back(c)
		divided.push_back(cd)
		
		divided.push_back(ab)
		divided.push_back(b)
		divided.push_back(cd)
		divided.push_back(d)
	return divided
