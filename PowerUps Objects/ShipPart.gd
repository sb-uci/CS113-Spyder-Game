extends Area2D

# ship parts should always be children of the progress controller
onready var ProgressController = get_parent()

func _on_ShipPart_body_entered(body):
	if body.is_in_group("Player"):
		ProgressController.advance()
		queue_free()
