extends KinematicBody2D

class_name Enemy

export var speed = 75
export var max_hp = 3
export var damage = 1

var health

onready var player = get_parent().get_node("Astronaut")
onready var player_box = _get_player_collision_node(player)
onready var navigation = get_parent().get_node("Navigation")
onready var hp = $HealthBar

func register_hit(damage):
	health -= damage
	hp.update_hp(health)
	if health <= 0:
		self.queue_free()

func _ready():
	_init_hp(max_hp)

func _physics_process(delta):
	_do_movement(delta)
	if _detect_player_collision(player):
		_on_collide_with_player(player)

func _do_movement(delta):
	var move_vectors = _navigate(speed * delta, global_position, player_box.global_position)
	for vector in move_vectors:
		self.position += vector # move entity, ignoring collision
	move_and_slide(Vector2(0,0)) # apply collision after movement
	
# Explanation for above: using collision movement will cause weird movement
# around corners (entity running into object, causing slow movement).
# By ignoring collision, the entity moves more "smoothly" (i.e. regular speed).
# But this can cause it to partially clip into obstacles (never fully clip,
# though). To avoid that, collision is applied on a non-movement after movement.

func _navigate(move_distance, start, end):
	var path = navigation.get_simple_path(start, end, true)
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
	hp.set_max(max_hp)
	hp.update_hp(max_hp)

func _on_collide_with_player(player_node):
	player_node.damage_player(1)
