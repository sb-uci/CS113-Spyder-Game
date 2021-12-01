extends StaticBody2D

onready var PARTS = [get_parent().get_node("ProgressController/ShipPart"),
					get_parent().get_node("ProgressController/ShipPart2"),
					get_parent().get_node("ProgressController/ShipPart3"),
					get_parent().get_node("ProgressController/ShipPart4"),
					get_parent().get_node("ProgressController/ShipPart5")
					]
onready var PLAYER = get_parent().get_node("Astronaut")

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
		return "I saw a piece fly off South-West of here"
	#If the part is NW
	if (PLAYER.position[0] > PART.position[0] && PLAYER.position[1] > PART.position[1]):
		return "I saw a piece fly off North-West of here"
	#If the part is SE
	if (PLAYER.position[0] < PART.position[0] && PLAYER.position[1] < PART.position[1]):
		return "I saw a piece fly off South-East of here"
	#If the part is NE
	if (PLAYER.position[0] < PART.position[0] && PLAYER.position[1] > PART.position[1]):
		return "I saw a piece fly off North-East of here"	

func findShipPart():
	var count = 0
	for part in PARTS:
		print(part)
		if (is_instance_valid(part)):
			return count;
		count += 1;
