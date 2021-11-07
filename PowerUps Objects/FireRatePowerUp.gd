extends "res://PowerUps Objects/PowerUp.gd"

export var FIRE_RATE_INCREASE = 1.65 #Greater the number, the faster the fire_rate

func _ready():
	pass

func _on_FireRate_PowerUp_body_entered(body):
	if body.is_in_group("Player"):
		for child in self.get_children():
			child.queue_free()
		PLAYER.set_fire_rate(FIRE_RATE_INCREASE)
		_create_powerUp_timer()
		
func _on_powerup_timeout():
	PLAYER.set_fire_rate(1/FIRE_RATE_INCREASE)
	queue_free()
