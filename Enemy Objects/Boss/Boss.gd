extends "res://Enemy Objects/Shooting Enemy.gd"

signal is_ready

enum stage {ONE, TWO, THREE, FOUR, FIVE}
enum phase {BULLET_PHASE, ADD_PHASE}
enum path_point {CENTER, LEFT, RIGHT}
enum sweep_dir {LEFT, RIGHT}
enum bullets {BASIC, BIG, WHIP, HOMING, BOUNCE}

export var BASIC_BULLET_DAMAGE = 1
export var BASIC_BULLET_SPEED = 175
export var BASIC_BULLET = preload("res://Enemy Objects/Boss/Basic Bullet.tscn")
export var BIG_BULLET_DAMAGE = 2
export var BIG_BULLET_SPEED = 100
export var BIG_BULLET = preload("res://Enemy Objects/Boss/Big Bullet.tscn")
export var WHIP_BULLET_DAMAGE = 1
export var WHIP_BULLET_SPEED = 20
export var WHIP_BULLET = preload("res://Enemy Objects/Boss/Whip Bullet.tscn")
export var HOMING_BULLET_DAMAGE = 1
export var HOMING_BULLET_SPEED = 90
export var HOMING_BULLET = preload("res://Enemy Objects/Boss/Homing Bullet.tscn")
export var BOUNCE_BULLET_DAMAGE = 1
export var BOUNCE_BULLET_SPEED = 125
export var BOUNCE_BULLET = preload("res://Enemy Objects/Boss/Bouncing Bullet.tscn")

export var BURST_FREQ = 1
export var ROT_BURST_FREQ = .35
export var SWEEP_BURST_FREQ = .1
export var SWEEP_FREQ = .05
export var SHOTGUN_FREQ = 1

export var BURST_NUM_BULLETS = 10
export var ROT_BURST_NUM_BULLETS = 10
export var SWEEP_BURST_NUM_BULLETS = 10
export var SHOTGUN_NUM_BULLETS = 8

export var SWEEP_DURATION = .75
export var ROT_BURST_DURATION = 3
export var SWEEP_BURST_DURATION = 1

export var SHOTGUN_SPREAD = 10
export var SHOTGUN_VARIANCE_FACTOR = 2

export var REBAKE_FREQ = .2 # how often to rebake the mesh (fixes a specific bug; don't worry abt it)

onready var cur_phase = phase.BULLET_PHASE
onready var cur_stage = stage.ONE
onready var sweep_state = sweep_dir.LEFT
onready var sweep_burst_state = sweep_dir.LEFT
onready var cur_bullet = bullets.BASIC

onready var next_point = path_point.LEFT
onready var path_point_center = global_position
onready var path_point_left = global_position - Vector2(100,-50)
onready var path_point_right = global_position + Vector2(100,50)

onready var soundBasicLaser = $BasicLaserSound

onready var SWEEP_TWEEN = $SweepTween
onready var BURST_TWEEN = $BurstTween
onready var SWEEP_BURST_TWEEN = $SweepingBurstTween

onready var SPAWNER = get_tree().get_root().get_node("World").get_node("Spawner")

var rot_burst_timer = 0
var burst_timer = 0
var sweep_timer = 0
var sweep_burst_timer = 0
var shotgun_timer = 0
var rebake_timer = 0
var rng = RandomNumberGenerator.new()

func register_hit(damage):
	health -= damage
	HP.update_hp(health)

func _ready_override():
	rng.randomize()
	_init_hp(MAX_HP)
	yield(HP.TWEEN, "tween_all_completed")
	set_process(true)
	set_physics_process(true)
	emit_signal("is_ready")
	PLAYER.apply_pseudo_impulse((PLAYER.global_position - global_position).normalized(), KNOCKBACK_FORCE - 100)

func _process_override(delta):
	_process_stage(delta)
	_process_phase(delta)
	_do_movement(delta)
	_do_attacks(delta)
	_elapse_timers(delta)
	if rebake_timer <= 0:
		NAVIGATION.rebake_mesh()
		rebake_timer = REBAKE_FREQ

func _physics_process_override(delta):
	#_do_movement(delta)
	if _detect_player_collision(PLAYER):
		_on_collide_with_player(PLAYER)
	
func _init_hp(max_hp):
	HP = get_tree().get_root().get_node("World").get_node("BossHealthBar")
	HP.show()
	health = max_hp
	HP.set_max(max_hp)

# =====================
#  STATES AND MOVEMENT
# =====================
func _process_stage(delta):
	pass
	
func _process_phase(delta):
	pass

func _do_attacks(delta):
	pass

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

# ==============
#  MAIN ATTACKS
# ==============
func _rotating_burst(duration):
	if BURST_TWEEN.is_active():
		return
	
	BURST_TWEEN.interpolate_method(self, "_rotate_burst_wrapper", 0, 360, duration, Tween.TRANS_LINEAR)
	BURST_TWEEN.start()
	
func _alternating_sweeping_burst():
	if SWEEP_BURST_TWEEN.is_active():
		return

	if sweep_burst_state == sweep_dir.LEFT:
		_sweeping_burst(-15, 15)
		sweep_burst_state = sweep_dir.RIGHT
	else:
		_sweeping_burst(15, -15)
		sweep_burst_state = sweep_dir.LEFT

func _alternating_sweep():
	if SWEEP_TWEEN.is_active():
		return

	if sweep_state == sweep_dir.LEFT:
		_sweep(205, 90)
		sweep_state = sweep_dir.RIGHT
	else:
		_sweep(-25, 90)
		sweep_state = sweep_dir.LEFT

func _shoot_player(bullet_type):
	if fire_timer > 0:
		return
	var bullet = _make_bullet(bullet_type)
	_shoot_target(PLAYER, bullet[0], bullet[1], soundBasicLaser)
	fire_timer = FIRE_RATE

func _shotgun_player(bullet_type):
	if shotgun_timer > 0:
		return
	_shotgun(PLAYER, bullet_type)
	shotgun_timer = SHOTGUN_FREQ

func _spaced_bursts(bullet_type):
	if burst_timer > 0:
		return
	_burst(BURST_NUM_BULLETS, 0, 0, bullet_type)
	burst_timer = BURST_FREQ

# ================
#  ATTACK HELPERS
# ================
func _burst(num_bullets, offset=0, bullet_speed_mod=0, bullet_type=null):
	var direction = offset # in degrees
	for i in range(num_bullets):
		var bullet = _make_current_bullet() if bullet_type == null else _make_bullet(bullet_type)
		_shoot_direction(direction, bullet[0], bullet[1] + bullet_speed_mod, soundBasicLaser)
		direction += 360/num_bullets

func _sweeping_burst(angle_start, angle_end):
	SWEEP_BURST_TWEEN.interpolate_method(self, "_sweeping_burst_wrapper", angle_start, angle_end, SWEEP_BURST_DURATION, Tween.TRANS_LINEAR)
	SWEEP_BURST_TWEEN.start()

func _sweep(angle_start, angle_end, duration=SWEEP_DURATION):
	SWEEP_TWEEN.interpolate_method(self, "_sweep_wrapper", angle_start, angle_end, duration, Tween.TRANS_LINEAR)
	SWEEP_TWEEN.start()

func _shotgun(target, bullet_type, num_bullets=SHOTGUN_NUM_BULLETS, spread=SHOTGUN_SPREAD):
	var direction = (target.global_position - global_position).angle() * 180/PI
	var bullet = _make_bullet(bullet_type)
	var bullet_speed = bullet[1]
	var speed_variance = bullet[1]/SHOTGUN_VARIANCE_FACTOR
	bullet[0].queue_free()
	
	for i in range(num_bullets):
		var angle_offset = rng.randf_range(-spread/2, spread/2)
		var speed_offset = rng.randf_range(-speed_variance/2, speed_variance/2)
		_shoot_direction(direction + angle_offset, _make_bullet(bullet_type)[0], bullet_speed + speed_offset, soundBasicLaser)

func _shoot_target(target, bullet, speed, sound):
	var direction = target.global_position - global_position
	bullet.rotation_degrees = direction.angle() * 180/PI
	bullet.apply_impulse(Vector2(), Vector2(speed, 0).rotated(direction.angle()))
	get_tree().get_root().get_node("World").add_child(bullet)
	sound.play()

func _shoot_direction(direction, bullet, speed, sound):
	bullet.rotation_degrees = direction
	bullet.apply_impulse(Vector2(), Vector2(speed, 0).rotated(direction * PI/180))
	get_tree().get_root().get_node("World").add_child(bullet)
	sound.play()

# ================
#  BULLET METHODS
# ================
func _make_current_bullet():
	return _make_bullet(cur_bullet)

func _make_bullet(bullet_type):
	match bullet_type:
		bullets.BASIC:
			return [_make_basic_bullet(), BASIC_BULLET_SPEED]
		bullets.BIG:
			return [_make_big_bullet(), BIG_BULLET_SPEED]
		bullets.WHIP:
			return [_make_whip_bullet(), WHIP_BULLET_SPEED]
		bullets.HOMING:
			return [_make_homing_bullet(HOMING_BULLET_SPEED), HOMING_BULLET_SPEED]
		bullets.BOUNCE:
			return [_make_bouncing_bullet(), BOUNCE_BULLET_SPEED]

func _make_basic_bullet():
	var bullet_instance = BASIC_BULLET.instance()
	bullet_instance.damage = BASIC_BULLET_DAMAGE
	bullet_instance.position = global_position
	return bullet_instance

func _make_big_bullet():
	var bullet_instance = BIG_BULLET.instance()
	bullet_instance.damage = BIG_BULLET_DAMAGE
	bullet_instance.position = global_position
	return bullet_instance
	
func _make_whip_bullet():
	var bullet_instance = WHIP_BULLET.instance()
	bullet_instance.damage = WHIP_BULLET_DAMAGE
	bullet_instance.position = global_position
	return bullet_instance
		
func _make_homing_bullet(speed):
	var bullet_instance = HOMING_BULLET.instance()
	bullet_instance.damage = HOMING_BULLET_DAMAGE
	bullet_instance.position = global_position
	bullet_instance.target = PLAYER
	bullet_instance.speed = speed
	return bullet_instance

func _make_bouncing_bullet():
	var bullet_instance = BOUNCE_BULLET.instance()
	bullet_instance.damage = BOUNCE_BULLET_DAMAGE
	bullet_instance.position = global_position
	return bullet_instance

# =========================
#  TWEENED ATTACK WRAPPERS
# =========================
# these methods are wrappers of attack helpers that allow the tween nodes
# to perform attacks using interpolate_method(), which passes only a single
# argument per method call
func _sweep_wrapper(direction):
	if sweep_timer > 0:
		return
	var bullet = _make_current_bullet()
	_shoot_direction(direction, bullet[0], bullet[1], soundBasicLaser)
	sweep_timer = SWEEP_FREQ

func _rotate_burst_wrapper(offset):
	if rot_burst_timer > 0:
		return
	_burst(ROT_BURST_NUM_BULLETS, offset, -50)
	rot_burst_timer = ROT_BURST_FREQ

func _sweeping_burst_wrapper(offset):
	if sweep_burst_timer > 0:
		return
	_burst(SWEEP_BURST_NUM_BULLETS, offset, -50)
	sweep_burst_timer = SWEEP_BURST_FREQ

# ===============
#  OTHER METHODS
# ===============
func _elapse_timers(delta):
	fire_timer -= delta
	rot_burst_timer -= delta
	burst_timer -= delta
	sweep_timer -= delta
	sweep_burst_timer -= delta
	shotgun_timer -= delta
	rebake_timer -= delta
	_handle_knockdown_cd(delta)
