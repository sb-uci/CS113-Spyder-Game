extends StaticBody2D

onready var PARTS = [get_parent().get_node("ProgressController/ShipPart"),
					get_parent().get_node("ProgressController/ShipPart2"),
					get_parent().get_node("ProgressController/ShipPart3"),
					get_parent().get_node("ProgressController/ShipPart4"),
					get_parent().get_node("ProgressController/ShipPart5")
					]
onready var PLAYER = get_parent().get_node("Astronaut")
onready var default_collision_layer = collision_layer
onready var default_collision_mask = collision_mask

func deactivate():
	visible = false
	collision_layer = 0
	collision_mask = 0

func activate():
	visible = true
	collision_layer = default_collision_layer
	collision_mask = default_collision_mask

func _on_Area2D_body_entered(body):
	$Label.text = checkPartPosition()
	$Label.visible = true


func _on_Area2D_body_exited(body):
	$Label.visible = false


func checkPartPosition():
	var PART = PARTS[findShipPart()]
	print(PLAYER.position,PART.position)
	#If the part is SW
	if (PLAYER.position[0] > PART.position[0] && PLAYER.position[1] < PART.position[1]):
		return "I saw a piece fly off\nSouth-West of here"
	#If the part is NW
	if (PLAYER.position[0] > PART.position[0] && PLAYER.position[1] > PART.position[1]):
		return "I saw a piece fly off\nNorth-West of here"
	#If the part is SE
	if (PLAYER.position[0] < PART.position[0] && PLAYER.position[1] < PART.position[1]):
		return "I saw a piece fly off\nSouth-East of here"
	#If the part is NE
	if (PLAYER.position[0] < PART.position[0] && PLAYER.position[1] > PART.position[1]):
		return "I saw a piece fly off\nNorth-East of here"	

func findShipPart():
	var count = 0
	for part in PARTS:
		print(part)
		if (is_instance_valid(part)):
			return count;
		count += 1;
