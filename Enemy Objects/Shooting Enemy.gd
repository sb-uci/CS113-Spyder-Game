extends "res://Enemy Objects/Enemy.gd"


onready var BULLET = preload("res://Enemy Objects/Enemy Bullet.tscn")
onready var BULLET_WIDTH = _get_bullet_sprite_width(BULLET)
onready var soundLaser = $LaserSound

export var BULLET_SPEED = 250
export var FIRE_RATE = 1.0
export var FIRE_RANGE = 1000
export var SHOT_TRACKING = 0

var fire_timer = 0

func _process(delta):
	var shoot_target = _predict_future_player_location(SHOT_TRACKING, BULLET_SPEED)
	if _can_shoot(shoot_target):
		_shoot(shoot_target)
	
	if fire_timer > 0:
		fire_timer -= delta
		
func _can_shoot(target):
	var is_visible_and_in_range = _is_on_screen() and _is_in_range(target)
	return is_visible_and_in_range and _has_line_of_sight(target)

func _is_in_range(target):
	return (target - global_position).length() <= FIRE_RANGE

func _do_movement(delta):
	var move_target = _predict_future_player_location(MOVEMENT_TRACKING, SPEED)
	var move_vectors = _navigate(SPEED * delta, global_position, move_target)
	for vector in move_vectors:
		if _can_shoot(move_target):
			break
		self.position += vector # move entity, ignoring collision
	move_and_slide(Vector2(0,0)) # apply collision after movement
	
	# makes the sprite face player
	var angle = global_position.angle_to_point(PLAYER.global_position) 
	sprite.flip_h = abs(angle) > PI/2

func _has_line_of_sight(target):
	# get points, define raycast "with width" to accomodate bullet size
	var pt1 = target
	var pt2 = global_position
	var upper_ray = _parallel_translate(pt1, pt2, BULLET_WIDTH)
	var lower_ray = _parallel_translate(pt1, pt2, -1 * BULLET_WIDTH)
	
	# perform raycasts
	var space_state = get_world_2d().direct_space_state
	var collision_mask = 0b00000000000000000011 # player and obstacle collision
	var raycast_upper = space_state.intersect_ray(upper_ray[1], upper_ray[0], [self], collision_mask)
	var raycast_lower = space_state.intersect_ray(lower_ray[1], lower_ray[0], [self], collision_mask)
	var raycast_center = space_state.intersect_ray(pt2, pt1, [self], collision_mask)
	
	return _line_of_sight_helper(raycast_upper, raycast_lower, raycast_center)

func _shoot(target):
	if fire_timer > 0:
		return
	
	var direction = target - global_position
	var bullet_instance = BULLET.instance()
	bullet_instance.damage = DAMAGE
	bullet_instance.position = global_position
	bullet_instance.rotation_degrees = direction.angle() * 180/PI
	bullet_instance.apply_impulse(Vector2(), Vector2(BULLET_SPEED, 0).rotated(direction.angle()))
	get_tree().get_root().add_child(bullet_instance)
	soundLaser.play()
	fire_timer = FIRE_RATE

func _parallel_translate(pt1, pt2, distance):
	var unit_direction = (pt2 - pt1).normalized()
	var orthogonal_unit = Vector2(-1 * unit_direction.y, unit_direction.x)
	var orthogonal_offset = orthogonal_unit * distance
	return [pt1 + orthogonal_offset, pt2 + orthogonal_offset]

func _line_of_sight_helper(upper, lower, mid):
	# no collision (empty) is considered valid for upper and lower
	var upper_valid = upper.empty() or upper.collider == PLAYER
	var lower_valid = lower.empty() or lower.collider == PLAYER
	# mid must collide with player hitbox to be valid
	var mid_valid = mid.empty() or mid.collider == PLAYER
	
	return upper_valid and lower_valid and mid_valid

func _get_bullet_sprite_width(bullet):
	var width = 0
	var temp_instance = bullet.instance()
	for child in temp_instance.get_children():
		if child.get_class() == "CollisionShape2D":
			width = child.shape.radius * 2
			break
	temp_instance.queue_free()
	return width
