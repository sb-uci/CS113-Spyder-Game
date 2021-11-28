extends Enemy

signal is_ready

enum state {DEFAULT, CHARGING}
enum path_point {CENTER, LEFT, RIGHT}

onready var cur_state = state.DEFAULT
onready var next_point = path_point.LEFT
onready var path_point_center = global_position
onready var path_point_left = global_position - Vector2(100,-50)
onready var path_point_right = global_position + Vector2(100,50)

func register_hit(damage):
	health -= damage
	HP.update_hp(health)

func _ready_override():
	SPEED = 50
	_init_hp(MAX_HP)
	yield(HP.TWEEN, "tween_all_completed")
	set_process(true)
	set_physics_process(true)
	emit_signal("is_ready")

func _process_override(delta):
	_handle_knockdown_cd(delta)

func _physics_process_override(delta):
	_do_movement(delta)
	if _detect_player_collision(PLAYER):
		_on_collide_with_player(PLAYER)
	
func _init_hp(max_hp):
	HP = get_tree().get_root().get_node("World").get_node("BossHealthBar")
	HP.show()
	health = max_hp
	HP.set_max(max_hp)

func _do_movement(delta):
	if cur_state == state.DEFAULT:
		var move_vector = (_get_next_point() - global_position).normalized()
		var collision = move_and_collide(move_vector * delta * SPEED)
		if collision != null:
			if collision.collider == PLAYER:
				_on_collide_with_player(PLAYER)
		_update_move_state(move_vector)

func _get_next_point():
	match next_point:
		path_point.LEFT:
			return path_point_left
		path_point.CENTER:
			return path_point_center
		path_point.RIGHT:
			return path_point_right
		
func _update_move_state(last_move):
	if (global_position - _get_next_point()).length() <= 1:
		match next_point:
			path_point.LEFT:
				next_point = path_point.CENTER
			path_point.RIGHT:
				next_point = path_point.CENTER
			path_point.CENTER:
				if last_move.x > 0: # if the boss was moving right, go right
					next_point = path_point.RIGHT
				else:
					next_point = path_point.LEFT
