extends RigidBody2D

var damage

func _on_Enemy_Bullet_body_entered(body):
	if body.is_in_group("Player"):
		body.damage_player(damage)
	queue_free()

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
