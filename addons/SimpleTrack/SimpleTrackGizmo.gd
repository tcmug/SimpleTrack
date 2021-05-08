extends EditorSpatialGizmo

func redraw():
	
	clear()

	var spatial = get_spatial_node()
	var lines = PoolVector3Array()

	var handles = PoolVector3Array()
	var controls = PoolVector3Array()
	var heights = PoolVector3Array()
	var control_heights = PoolVector3Array()
	var tilts = PoolVector3Array()
	var curve: Curve3D = spatial.curve
	
	var track_half_width = spatial.width * 0.5
	for i in range(curve.get_point_count()):
		var point = curve.get_point_position(i)
		var control =  curve.get_point_out(i)
		var s = Vector3(point.x, 0, point.z)
		handles.push_back(s)
		heights.push_back(s + Vector3(0, point.y, 0))

		var cp = point + control
		var h = Vector3(cp.x, 0, cp.z)
		controls.push_back(h)
		control_heights.push_back(h + Vector3(0, cp.y, 0))
		
		var dir = control.normalized()
		var up = Vector3(0, 1, 0).rotated(dir, curve.get_point_tilt(i))
		tilts.push_back(
			point + (up.cross(dir) * (track_half_width * 2))
		)
		lines.push_back(s)
		lines.push_back(h)
		
		lines.push_back(s + Vector3(0, point.y, 0))
		lines.push_back(h + Vector3(0, cp.y, 0))

		lines.push_back(s + Vector3(0, point.y, 0))
		lines.push_back(s + + Vector3(0, point.y, 0) + (up.cross(dir) * (track_half_width * 2)))

	var lines_material = get_plugin().get_material("axis", self)
	var handles_material = get_plugin().get_material("handles", self)
	var heights_material = get_plugin().get_material("heights", self)
	var controls_material = get_plugin().get_material("controls", self)
	var tilts_material = get_plugin().get_material("tilts", self)
	add_lines(lines, lines_material, false)
	add_handles(handles, handles_material)
	add_handles(controls, controls_material)
	add_handles(heights, heights_material)
	add_handles(control_heights, heights_material)
	add_handles(tilts, tilts_material)
	
func set_handle(index, camera, point):
	var spatial = get_spatial_node()
	var curve: Curve3D = spatial.curve
	var num_points := curve.get_point_count()

	if get_plugin().move_vertical:
		var what_to_move = index / num_points 
		match what_to_move:
			0: index = index + 2 * num_points
			1: index = index + 3 * num_points
		
	if index >= num_points * 4:
		# Move tilt
		var i = index - num_points * 4
		var curve_point = curve.get_point_position(i)
		var curve_out = curve.get_point_out(i)
		
		var origin = camera.project_position(point, 0)
		var dir = camera.project_position(point, 1) - origin
		var up := Vector3(0, 1, 0)
		var plane := Plane(curve_point, curve_point + up, curve_point + (curve_out.cross(up).normalized()))
		var c := plane.intersects_ray(origin, dir)
		var plane_point = (c - curve_point).normalized()
		var track_right = up.cross(curve_out).normalized()
		var angle = track_right.angle_to(plane_point)
		if up.dot(plane_point) < 0:
			angle = -angle
		curve.set_point_tilt(i, angle)

	elif index >= num_points * 3:
		# Move control height points
		var i = index - num_points * 3
		var curve_point = curve.get_point_position(i)
		var curve_out = curve.get_point_out(i)
		var origin = camera.project_position(point, 0)
		var dir = camera.project_position(point, 1) - origin
		var up := Vector3(0, 1, 0)
		var pt = curve_point + curve_out
		var plane := Plane(pt, pt + up, pt + dir.cross(up))
		var c := plane.intersects_ray(origin, dir)
		var outin = Vector3(
			curve_out.x,
			c.y - curve_point.y,
			curve_out.z
		)
		curve.set_point_out(i, outin)
		curve.set_point_in(i, outin * -1)
		
	elif index >= num_points * 2:
		# Move handle height points
		var i = index - num_points * 2
		var curve_point = curve.get_point_position(i)	
		var origin = camera.project_position(point, 0)
		var dir = camera.project_position(point, 1) - origin
		var up := Vector3(0, 1, 0)
		var plane := Plane(curve_point, curve_point + up, curve_point + dir.cross(up))
		var c := plane.intersects_ray(origin, dir)
		curve.set_point_position(i, Vector3(
			curve_point.x,
			c.y,
			curve_point.z
		))

	elif index >= num_points * 1:
		# Move control points
		var i = index - num_points
		var curve_point = curve.get_point_position(i)
		var curve_out = curve.get_point_out(i)
		var origin = camera.project_position(point, 0)
		var dir = camera.project_position(point, 1) - origin
		var plane := Plane(Vector3(0, 1, 0), 0)
		var c = plane.intersects_ray(origin, dir)
		var outin = Vector3(
			c.x - curve_point.x,
			curve_out.y,
			c.z - curve_point.z
		)
		curve.set_point_out(i, outin)
		curve.set_point_in(i, outin * -1)
		
	else:
		# Move handle points
		var i = index
		var origin = camera.project_position(point, 0)
		var dir = camera.project_position(point, 1) - origin
		var plane := Plane(Vector3(0, 1, 0), 0)
		var c = plane.intersects_ray(origin, dir)
		curve.set_point_position(i, Vector3(
			c.x,
			curve.get_point_position(i).y,
			c.z
		))
		
	spatial.update_gizmo()

func get_handle_name(index):
	var spatial = get_spatial_node()
	var curve: Curve3D = spatial.curve
	var i = index % curve.get_point_count()
	return "Point %s" % i

func get_handle_value(index):
	var spatial = get_spatial_node()
	var curve: Curve3D = spatial.curve
	var num_points := curve.get_point_count()
	if index >= num_points * 4:
		return rad2deg(curve.get_point_tilt(index - num_points * 4))
	return index % curve.get_point_count()

func commit_handle(_index, _what, _default=false):
	var spatial = get_spatial_node()
	spatial.rebuild_track(true)

