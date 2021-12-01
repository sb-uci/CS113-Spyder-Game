extends "res://Enemy Objects/Shooting Enemy.gd"

func refresh_node_references():
	PLAYER = get_parent().get_node("Astronaut")
	NAVIGATION = get_parent().get_node("FlyingNavigation")
