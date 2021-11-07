extends "res://Enemy Objects/Enemy.gd"

onready var BULLET = preload("res://Enemy Objects/Enemy Bullet.tscn")
onready var BULLET_WIDTH = _get_bullet_sprite_width(BULLET)

onready var sprite = $AnimatedSprite

export var BULLET_SPEED = 250
export var FIRE_RATE = 1.5
export var TRACKING_AMOUNT = 0

var fire_timer = 0

func _ready():
	MAX_HP = 2 # override parent class health
	SPEED = 75 # override parent class speed
	_init_hp(MAX_HP)
		
	
func _process(delta):
	var move_and_shoot_target = _predict_future_player_location(TRACKING_AMOUNT)
	if _has_line_of_sight(move_and_shoot_target):
		_shoot(move_and_shoot_target)
	
	if fire_timer > 0:
		fire_timer -= delta

func _do_movement(delta):
	var move_target = _predict_future_player_location(TRACKING_AMOUNT)
	var move_vectors = _navigate(SPEED * delta, global_position, move_target)
	for vector in move_vectors:
		if _has_line_of_sight(PLAYER.get_collision_center()):
			break
		self.position += vector # move entity, ignoring collision
		sprite.flip_h = vector.x > 0
	move_and_slide(Vector2(0,0)) # apply collision after movement

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

func _predict_bullet_travel_time(target):
	var distance = target - global_position
	return distance.length() / BULLET_SPEED

func _predict_future_player_location(cycles):
	var player_vector = PLAYER.get_velocity()
	var predicted_location = PLAYER.get_collision_center()
	var time_offset = 0
	var distance_offset = 0
	
	for i in range(cycles):
		time_offset = _predict_bullet_travel_time(predicted_location)
		distance_offset = player_vector * time_offset
		predicted_location = PLAYER.get_collision_center() + distance_offset
	
	return predicted_location

func _get_bullet_sprite_width(bullet):
	var width = 0
	var temp_instance = bullet.instance()
	for child in temp_instance.get_children():
		if child.get_class() == "CollisionShape2D":
			width = child.shape.radius * 2
			break
	temp_instance.queue_free()
	return width
