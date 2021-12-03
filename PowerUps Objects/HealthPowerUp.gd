extends PowerUp

export var HEALTH_INCREASE = 1 #Greater value = more health

onready var soundHeal = $HealSound

func _process(delta):
	lifetime -= delta
	if lifetime <= 3 and lifetime > 1.5:
		_flash_sprite($Sprite, $Tween)
	elif lifetime <= 1.5:
		_flash_sprite($Sprite, $Tween, 0.15)

func _ready():
	pass

func _on_Health_PowerUp_body_entered(body):
	if body.is_in_group("Player"):
		if PLAYER.health != PLAYER.MAX_HP:
			for child in get_children():
				if child != soundHeal:
					child.queue_free()
			soundHeal.play()
			PLAYER.heal(HEALTH_INCREASE)
			_create_powerUp_timer() # if health pack queue_frees here, sound won't play

func _on_powerup_timeout():
	queue_free()
