extends "res://Enemy Objects/Enemy.gd"

func _ready():
	# override parent class values
	MAX_HP = 6
	SPEED = 35
	DAMAGE = 2
	KNOCKBACK_FORCE = 400
	_init_hp(MAX_HP)
