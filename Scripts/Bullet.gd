extends RigidBody2D

func _on_Bullet_body_entered(body):
	if !body.is_in_group("Player"):
		if body.is_in_group("Enemies"):
			body.queue_free()
		queue_free()

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
