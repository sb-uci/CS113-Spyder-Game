extends "res://Enemy Objects/Enemy.gd"

func _do_movement(delta):
	var move_vectors = _navigate(SPEED * delta, global_position, PLAYER.get_collision_center())
	for vector in move_vectors:
		self.position += vector # move entity, ignoring collision
		sprite.flip_h = vector.x > 0
	move_and_slide(Vector2(0,0)) # apply collision after movement
