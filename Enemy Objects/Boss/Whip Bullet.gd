extends "res://Enemy Objects/Enemy Bullet.gd"

export var impulse_strength = 3
export var acceleration = 1.05

func _process(delta):
	apply_central_impulse(linear_velocity.normalized() * impulse_strength)
	impulse_strength *= acceleration
