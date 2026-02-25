extends Node

var toggled := false

func interact():
	toggled = !toggled
	print("NPC interacted! toggled=", toggled)
