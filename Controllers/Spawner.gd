extends Node2D

export var rate = 30 # avg number of spawns per minute
export var basic_weight = 7 # likelihood of basic enemy spawning
export var flyer_weight = 2 # likelihood of flyer enemy spawning
export var shooter_weight = 2 # likelihood of shooter enemy spawning
export var brute_weight  = 2 # likelihood of brute enemy spawning
export var flyer_time_comp = 1 # time compensation for spawning flyer
export var shooter_time_comp = 2 # time compensation for spawning shooter
export var brute_time_comp = 2 # time compensation for spawning brute
export var interval_thresh = 10 # clips spawn intervals to not be too long
export var screen_edge_buffer = 50 # n pixel "deadzone" around screen where spawning cannot occur
export var enabled = true

export var design_width = 320 # design resolution; different from real resolution
export var design_height = 180

# define boundary within which enemies cannot spawn
onready var horizontal = design_width + 2*screen_edge_buffer
onready var vertical = design_height + 2*screen_edge_buffer
onready var box_perimeter = 2*horizontal + 2*vertical

onready var rng = RandomNumberGenerator.new()

onready var basic = preload("res://Enemy Objects/Enemy.tscn")
onready var flyer = preload("res://Enemy Objects/Flying Enemy.tscn")
onready var shooter = preload("res://Enemy Objects/Shooting Enemy.tscn")
onready var brute = preload("res://Enemy Objects/Brute Enemy.tscn")

onready var DIFFICULTY_CONTROLLER = get_tree().get_root().get_node("World").get_node("ProgressController").get_node("DifficultyController")

var next_spawn

func change_rate(new_rate):
	rate = new_rate
	
func change_weights(weights):
	basic_weight = weights[0]
	flyer_weight = weights[1]
	shooter_weight = weights[2]
	brute_weight = weights[3]

func _ready():
	rng.randomize()
	next_spawn = _generate_interval()

func _process(delta):
	if enabled:
		if next_spawn <= 0:
			_spawn()
			next_spawn = _generate_interval() + next_spawn
			if next_spawn > interval_thresh:
				next_spawn = interval_thresh
			print("next spawn in {sec} seconds".format({"sec":next_spawn}))
		else:
			next_spawn -= delta

func _spawn():
	var point = _generate_spawn_point()
	var enemy = _choose_enemy()
	print("Spawning enemy at {point}".format({"point":point}))
	enemy = DIFFICULTY_CONTROLLER.scale_enemy_stats(enemy)
	get_tree().get_root().get_node("World").add_child(enemy)
	enemy.position = point

func _generate_interval():
	var t = rng.randf() # generates number between 0 and 1
	return -1 * ((log(t)/rate) * 60)

func _generate_spawn_point():
	var point = rng.randf_range(0, box_perimeter)
	var screen = get_viewport()
	if (point < horizontal):
		# point is on top horizontal border
		return global_position + Vector2(point - (horizontal/2), vertical/2)
	elif (point < horizontal + vertical):
		# point is on right vertical border
		point -= horizontal
		return global_position + Vector2(horizontal/2, point - (vertical/2))
	elif (point < 2*horizontal + vertical):
		# point is on bottom horizontal border
		point -= horizontal + vertical
		return global_position + Vector2(point - (horizontal/2), -1 * (vertical/2))
	else:
		# point is on left vertical border
		point -= 2*horizontal + vertical
		return global_position + Vector2(-1 * (horizontal/2), point - (vertical/2))

func _choose_enemy():
	var total_weight = basic_weight + flyer_weight + shooter_weight + brute_weight
	var enemy_seed = rng.randf_range(0,total_weight)
	if enemy_seed <= basic_weight:
		return basic.instance()
		
	elif enemy_seed <= basic_weight + flyer_weight:
		next_spawn += flyer_time_comp
		return flyer.instance()
		
	elif enemy_seed <= basic_weight + flyer_weight + shooter_weight:
		next_spawn += shooter_time_comp
		return shooter.instance()
		
	else:
		next_spawn += brute_time_comp
		return brute.instance()
