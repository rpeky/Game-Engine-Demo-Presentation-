extends Node

@export var flip_2d_tile := true
@export var sync_toggle_state := true

var toggled := false

func interact():
	toggled = !toggled

	var root := get_tree().current_scene
	if root == null:
		push_warning("current_scene is null")
		return

	if sync_toggle_state and root.has_method("set_toggle2d_state"):
		root.call("set_toggle2d_state", toggled)
	else:
		print("Root missing set_toggle2d_state")

	if flip_2d_tile and root.has_method("flip_2d_tile_under_2d_player"):
		root.call("flip_2d_tile_under_2d_player")
	else:
		print("Root missing flip_2d_tile_under_2d_player")
