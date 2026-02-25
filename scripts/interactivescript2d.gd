extends Node

var toggled := false

func interact():
	toggled = !toggled
	print("Sanity check: toggled=", toggled)

	var root := get_tree().root.get_node_or_null("RootNode")
	if root and root.has_method("set_toggle2d_state"):
		root.set_toggle2d_state(toggled)
