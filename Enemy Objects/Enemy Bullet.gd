extends RigidBody2D

export var lifetime = 10 # seconds before forced dequeue

var damage

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_Enemy_Bullet_body_entered(body):
	if body.is_in_group("Player"):
		body.damage_player(damage)
	elif body.is_in_group("Bullet") or body.is_in_group("Boss"):
		return
	queue_free()
