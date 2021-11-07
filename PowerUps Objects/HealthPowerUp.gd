extends PowerUp

export var HEALTH_INCREASE = 1 #Greater value = more health

func _ready():
	pass

func _on_Health_PowerUp_body_entered(body):
	if body.is_in_group("Player"):
		if PLAYER.health != PLAYER.MAX_HP:
			PLAYER.health += HEALTH_INCREASE
			PLAYER.HEALTH_BAR.update_hp(PLAYER.health)
			queue_free()
