extends "res://Enemy Objects/Enemy.gd"

func _ready():
	speed = 100 # override parent class speed

func do_movement(delta):
	var move_vectors = navigate(speed * delta, global_position, player_box.global_position)
	for vector in move_vectors:
		if has_line_of_sight():
			break
		self.position += vector # move entity, ignoring collision
	move_and_slide(Vector2(0,0)) # apply collision after movement

func has_line_of_sight():
	var space_state = get_world_2d().direct_space_state
	var pt1 = player_box.global_position
	var pt2 = self.global_position
	var collision_mask = 0b00000000000000000011 # player and obstacle collision
	var raycast = space_state.intersect_ray(pt2, pt1, [self], collision_mask)
	return raycast.collider == player
