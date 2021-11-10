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

var knockback_cd = 0
var health
var PLAYER
var NAVIGATION

onready var sprite = $AnimatedSprite
onready var player_node_name = "Astronaut"
onready var navigate_node_name = "Navigation"
onready var HP = $HealthBar
onready var POWERUP_LIST = [preload("res://PowerUps Objects/MovementPowerUp.tscn"),
							preload("res://PowerUps Objects/FireRatePowerUp.tscn"),
							preload("res://PowerUps Objects/HealthPowerUp.tscn")]

func register_hit(DAMAGE):
	health -= DAMAGE
	HP.update_hp(health)
	if health <= 0:
		_spawn_powerup()
		self.queue_free()

# when an enemy is spawned, it's not attached to the tree, so it's PLAYER and NAVIGATION
# references will be null. After adding to tree, run this.
func refresh_node_references():
	PLAYER = get_parent().get_node(player_node_name)
	NAVIGATION = get_parent().get_node(navigate_node_name)

func _ready():
	refresh_node_references()
	_init_hp(MAX_HP)
	
func _process(delta):
	if knockback_cd > 0:
		knockback_cd -= delta

func _physics_process(delta):
	_do_movement(delta)
	if _detect_player_collision(PLAYER):
		_on_collide_with_player(PLAYER)

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

func _get_player_collision_node(player_node):
	for child in player_node.get_children():
		if child.get_class() == "CollisionShape2D":
			return child

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
		var powerUpChosen = powerUpDropChance.randi_range(0, POWERUP_LIST.size()-1)
		var powerUp = POWERUP_LIST[powerUpChosen].instance()
		powerUp.position = global_position
		get_parent().add_child(powerUp)
	
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
