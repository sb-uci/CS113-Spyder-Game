extends PowerUp

export var MOVEMENT_SPEED_INCREASE = 1.5 #Greater value = Faster
func _ready():
	pass

func _on_Movement_PowerUp_body_entered(body):
	if body.is_in_group("Player"):
		for child in self.get_children():
			child.queue_free()
		PLAYER.set_speed(PLAYER.MAX_SPEED*MOVEMENT_SPEED_INCREASE)
		_create_powerUp_timer()
		
func _on_powerup_timeout():
	PLAYER.set_speed(PLAYER.MAX_SPEED/MOVEMENT_SPEED_INCREASE)
	queue_free()


