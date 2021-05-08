tool
extends EditorPlugin

const TrackBuilderEditorPlugin = preload("SimpleTrackEditorPlugin.gd")
var gizmo_plugin = TrackBuilderEditorPlugin.new()

func _enter_tree():
	# Add editor gizmo
	add_spatial_gizmo_plugin(gizmo_plugin)
	# Add content type
	add_custom_type("SimpleTrack", "MeshInstance", preload("SimpleTrack.gd"), preload("icon.png"))

func _exit_tree():
	remove_spatial_gizmo_plugin(gizmo_plugin)
	remove_custom_type("SimpleTrack")

func forward_spatial_gui_input(camera: Camera, event: InputEvent):
	if event is InputEventKey:
		if event.scancode == KEY_CONTROL:
			gizmo_plugin.move_vertical = event.pressed

func handles(object):
	return object is SimpleTrack
