extends RigidBody2D

export var lifetime = 10 # seconds before forced dequeue (screen exit signal not always working)

var damage

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_Bullet_body_entered(body):
	if !body.is_in_group("Player"):
		if body is Enemy:
			body.register_hit(damage)
		queue_free()

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
