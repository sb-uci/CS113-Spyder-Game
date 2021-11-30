extends KinematicBody2D

class_name Enemy

export var SPEED = 75.0
export var MAX_HP = 3.0
export var DAMAGE = 1.0
export var KNOCKBACK_FORCE = 0
export var KNOCKBACK_COOLDOWN = 1
export var POWERUP_DROP_CHANCE = 0.35
export var MOVEMENT_TRACKING = 0
export var TYPE = "basic"
export var POWERUP_WEIGHTS = [1,1,1]

var knockback_cd = 0
var health
var PLAYER
var NAVIGATION
var GLOBALS
var INDICATOR

onready var sprite = $AnimatedSprite
onready var HP = $HealthBar
onready var POWERUP_LIST = [preload("res://PowerUps Objects/MovementPowerUp.tscn"),
							preload("res://PowerUps Objects/FireRatePowerUp.tscn"),
							preload("res://PowerUps Objects/HealthPowerUp.tscn")]
onready var INDICATOR_SCENE = preload("res://UI Objects/Enemy Indicator.tscn")

func register_hit(damage):
	health -= damage
	HP.update_hp(health)
	if health <= 0:
		_spawn_powerup()
		kill()

func kill():
	INDICATOR.queue_free()
	self.queue_free()

# when an enemy is spawned, it's not attached to the tree, so it's PLAYER and NAVIGATION
# references will be null. After adding to tree, run this.
func refresh_node_references():
	PLAYER = get_parent().get_node("Astronaut")
	NAVIGATION = get_parent().get_node("Navigation")
	GLOBALS = get_parent().get_node("Globals")

# Godot doesn't allow child classes to replace _ready(), _process(), etc of parent class.
# Instead, it calls both! Using a separate method unique to the parent class allows
# the child classes to override that method instead
func _ready_override():
	refresh_node_references()
	_init_hp(MAX_HP)
	_spawn_indicator()

func _process_override(delta):
	_handle_knockdown_cd(delta)
	_check_indicator_visibility()
	
func _physics_process_override(delta):
	_do_movement(delta)
	if _detect_player_collision(PLAYER):
		_on_collide_with_player(PLAYER)

func _ready():
	_ready_override()
	
func _process(delta):
	_process_override(delta)

func _physics_process(delta):
	_physics_process_override(delta)

func _do_movement(delta):
	var move_target = _predict_future_player_location(MOVEMENT_TRACKING, SPEED)
	var move_vectors = _navigate(SPEED * delta, global_position, move_target)
	for vector in move_vectors:
		self.position += vector # move entity, ignoring collision
		sprite.flip_h = vector.x > 0
	move_and_slide(Vector2(0,0)) # apply collision after movement
	
# Explanation for above: using collision movement will cause weird movement
# around corners (entity running into object, causing slow movement).
# By ignoring collision, the entity moves more "smoothly" (i.e. regular speed).
# But this can cause it to partially clip into obstacles (never fully clip,
# though). To avoid that, collision is applied after movement.

func _navigate(move_distance, start, end):
	var path = NAVIGATION.get_simple_path(start, end, true)
	path.remove(0) # first point is start point
	
	var vectors = [] # discreet movement steps
	for i in range(path.size()):
		var distance_to_point = start.distance_to(path[0])
		var move_vector = (path[0] - start).normalized()
		if move_distance <= distance_to_point:
			# entity CAN'T move all the way to next point
			vectors.append(move_vector * move_distance)
			break
		elif move_distance < 0:
			break
		else:
			# entity CAN move all teh way to next point
			vectors.append(move_vector * distance_to_point)
			move_distance -= distance_to_point
			start = path[0]
			path.remove(0)
	
	return vectors
	
func _detect_player_collision(player_node):
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider == player_node:
			return true
	return false

func _init_hp(max_hp):
	health = max_hp
	HP.set_max(max_hp)
	HP.update_hp(max_hp)

func _on_collide_with_player(player_node):
	var hit_direction = player_node.global_position - global_position
	player_node.damage_player(DAMAGE)
	
	if knockback_cd <= 0:
		player_node.apply_pseudo_impulse(hit_direction, KNOCKBACK_FORCE)
		knockback_cd = KNOCKBACK_COOLDOWN
	
func _spawn_powerup():
	var powerUpDropChance = RandomNumberGenerator.new()
	powerUpDropChance.randomize()
	var willDrop = powerUpDropChance.randf_range(0, 1)
	if (willDrop < POWERUP_DROP_CHANCE):
		var powerUp = POWERUP_LIST[_choose_powerup(powerUpDropChance)].instance()
		powerUp.position = global_position
		get_parent().add_child(powerUp)

func _choose_powerup(rng):
	# generate random number
	var weightSum = 0
	for weight in POWERUP_WEIGHTS:
		weightSum += weight
	var randNum = rng.randi_range(0, weightSum-1)
	
	# map random number to choice
	weightSum = 0
	var i = 0
	for weight in POWERUP_WEIGHTS:
		weightSum += weight
		if randNum < weightSum:
			return i
		i += 1

# helper for _predict_future_player_location; calculates travel time to target by enemy or bullet
func _predict_travel_time(target, speed):
	var distance = target - global_position
	return distance.length() / speed

# estimates future player position assuming optimal pathing by enemy or bullet
func _predict_future_player_location(cycles, speed):
	var player_vector = PLAYER.get_velocity()
	var predicted_location = PLAYER.get_collision_center()
	var time_offset = 0
	var distance_offset = 0
	
	for i in range(cycles):
		time_offset = _predict_travel_time(predicted_location, speed)
		distance_offset = player_vector * time_offset
		predicted_location = PLAYER.get_collision_center() + distance_offset
	
	return predicted_location

func _spawn_indicator():
	INDICATOR = INDICATOR_SCENE.instance()
	INDICATOR.set_enemy(self)
	get_tree().get_root().get_node("World").add_child(INDICATOR)

func _is_on_screen():
	var x_low = GLOBALS.cam_center.x - GLOBALS.cam_width/2
	var x_high = GLOBALS.cam_center.x + GLOBALS.cam_width/2
	var y_low = GLOBALS.cam_center.y - GLOBALS.cam_height/2
	var y_high = GLOBALS.cam_center.y + GLOBALS.cam_height/2
	
	var is_in_x_bound = global_position.x >= x_low and global_position.x <= x_high
	var is_in_y_bound = global_position.y >= y_low and global_position.y <= y_high
	return is_in_x_bound and is_in_y_bound
	
func _handle_knockdown_cd(delta):
	if knockback_cd > 0:
		knockback_cd -= delta

func _check_indicator_visibility():
	if _is_on_screen():
		INDICATOR.visible = false
		INDICATOR.set_process(false)
	else:
		INDICATOR.visible = true
		INDICATOR.set_process(true)
