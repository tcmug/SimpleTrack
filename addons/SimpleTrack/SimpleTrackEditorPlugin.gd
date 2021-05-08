extends EditorSpatialGizmoPlugin

const TrackBuilderGizmo = preload("SimpleTrackGizmo.gd")
var move_vertical: bool = false

func _init():
	create_handle_material("axis")
	create_handle_material("handles")
	create_handle_material("controls")
	create_handle_material("heights")
	create_handle_material("tilts")
	get_material("controls", null).albedo_color = Color(1, 0, 1)
	get_material("heights", null).albedo_color = Color(0, 1, 0)
	get_material("tilts", null).albedo_color = Color(0, 0, 1)

func create_gizmo(spatial):
	if spatial is SimpleTrack:
		return TrackBuilderGizmo.new()
	else:
		return null
