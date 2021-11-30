extends KinematicBody2D

export var lifetime = 2.5 # seconds before forced dequeue

var target
var speed
var damage

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		
	var move_vector = target.global_position - global_position
	var collision = move_and_collide(move_vector.normalized() * delta * speed)
	rotation = move_vector.angle()
	_handle_collision(collision)

# this is a dummy function that just allows existing bullet code to treat
# this object as a bullet (which is a rigidbody) without failing
func apply_impulse(vector1, vector2):
	return

func _handle_collision(collision):
	if collision == null:
		return
	var body = collision.collider
	if body.is_in_group("Player"):
		body.damage_player(damage)
	elif body.is_in_group("Bullet") or body.is_in_group("Boss"):
		return
	queue_free()
