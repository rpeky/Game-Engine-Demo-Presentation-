extends Node

var toggled := false

func interact():
	toggled = !toggled
	var mesh := get_parent().get_node("MeshInstance3D") as MeshInstance3D
	if mesh.material_override == null:
		mesh.material_override = StandardMaterial3D.new()

	var mat := mesh.material_override as StandardMaterial3D
	mat.albedo_color = Color(0.2, 1.0, 0.2) if toggled else Color(1.0, 0.2, 0.2)
