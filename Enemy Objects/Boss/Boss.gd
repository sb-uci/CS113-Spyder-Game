extends "res://Enemy Objects/Shooting Enemy.gd"

signal is_ready

enum stage {ONE, TWO, THREE, FOUR, FIVE}
enum phase {BULLET_PHASE, ADD_PHASE, ADD_TO_BULLET}
enum path_point {CENTER, LEFT, RIGHT}
enum sweep_dir {LEFT, RIGHT}
enum bullets {BASIC, BIG, WHIP, HOMING, BOUNCE}

# INNATE BULLET PROPERTIES
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
export var HOMING_BULLET_SPEED = 75
export var HOMING_BULLET = preload("res://Enemy Objects/Boss/Homing Bullet.tscn")
export var BOUNCE_BULLET_DAMAGE = 1
export var BOUNCE_BULLET_SPEED = 125
export var BOUNCE_BULLET = preload("res://Enemy Objects/Boss/Bouncing Bullet.tscn")

# ATTACK TIMING (higher is slower)
export var BURST_FREQ = 1
export var ROT_BURST_FREQ = .4
export var SWEEP_BURST_FREQ = .1
export var SWEEP_FREQ = .05
export var SHOTGUN_FREQ = 1

# ATTACK QUANTITY
export var BURST_NUM_BULLETS = 8
export var ROT_BURST_NUM_BULLETS = 10
export var SWEEP_BURST_NUM_BULLETS = 10
export var SHOTGUN_NUM_BULLETS = 8

# ATTACK DURATION
export var SWEEP_DURATION = .75 # smaller is easier
export var ROT_BURST_DURATION = 3 # doesn't actually matter, I think
export var SWEEP_BURST_DURATION = 1 # smaller is harder

# SHOTGUN PROPERTIES
export var SHOTGUN_SPREAD = 10 # bigger is harder, until it's not
export var SHOTGUN_VARIANCE_FACTOR = 2 # bigger is harder

# MISC TIMING
export var PHASE_SWITCH_FREQ = 10 # how long boss spends in each phase (NOT stage)
export var REBAKE_FREQ = .2 # how often to rebake the mesh (fixes a specific bug; don't worry abt it)

# ENUM DEFAULTS
onready var cur_phase = phase.ADD_PHASE
onready var cur_stage = stage.ONE
onready var sweep_state = sweep_dir.LEFT
onready var sweep_burst_state = sweep_dir.LEFT
onready var cur_bullet = bullets.BASIC

# MOVEMENT DEFAULTS
onready var next_point = path_point.LEFT
onready var path_point_center = global_position
onready var path_point_left = global_position - Vector2(100,-50)
onready var path_point_right = global_position + Vector2(100,50)

# SOUNDS
onready var soundBasicLaser = $BasicLaserSound

# TWEENS
onready var SWEEP_TWEEN = $SweepTween
onready var BURST_TWEEN = $BurstTween
onready var SWEEP_BURST_TWEEN = $SweepingBurstTween

# MISC
onready var SPAWNER = get_tree().get_root().get_node("World").get_node("Spawner")

# PROPERTIES
var phase_timer = PHASE_SWITCH_FREQ
var rot_burst_timer = 0
var burst_timer = 0
var sweep_timer = 0
var sweep_burst_timer = 0
var shotgun_timer = 0
var rebake_timer = 0
var rng = RandomNumberGenerator.new()

# call to damage the boss
func register_hit(damage):
	health -= damage
	HP.update_hp(health)

# overrides the _ready() method body in parent class
func _ready_override():
	rng.randomize()
	_init_hp(MAX_HP)
	yield(HP.TWEEN, "tween_all_completed")
	set_process(true)
	set_physics_process(true)
	emit_signal("is_ready")
	PLAYER.apply_pseudo_impulse((PLAYER.global_position - global_position).normalized(), KNOCKBACK_FORCE - 100)

# overrides the _process() method body in parent class
func _process_override(delta):
	if Input.is_action_just_pressed("dev_skip"):
		register_hit(MAX_HP * .2)
	_process_stage()
	_process_phase(delta)
	_do_movement(delta)
	_do_attacks(delta)
	_elapse_timers(delta)
	if rebake_timer <= 0:
		NAVIGATION.rebake_mesh()
		rebake_timer = REBAKE_FREQ

# overrides the _physics_process() method body in parent class
func _physics_process_override(delta):
	#_do_movement(delta)
	if _detect_player_collision(PLAYER):
		_on_collide_with_player(PLAYER)
	
# initializes hp and healthbar with fancy animation sequence
func _init_hp(max_hp):
	HP = get_tree().get_root().get_node("World").get_node("BossHealthBar")
	HP.show()
	health = max_hp
	HP.set_max(max_hp)

# =====================
#  STATES AND MOVEMENT
# =====================
# handle stage-based actions, change stages
func _process_stage():
	match cur_stage:
		stage.ONE:
			if _health_percent() <= 0.8:
				cur_stage = stage.TWO
				BURST_NUM_BULLETS += 2
				_attack_reset()
				_clear_bullets()
		stage.TWO:
			if _health_percent() <= 0.6:
				cur_stage = stage.THREE
				BURST_FREQ += 0.25
				BURST_NUM_BULLETS -= 2
				SWEEP_BURST_FREQ += 0.05
				_attack_reset()
				_clear_bullets()
		stage.THREE:
			if _health_percent() <= 0.4:
				cur_stage = stage.FOUR
				SWEEP_BURST_FREQ -= 0.05
				_attack_reset()
				_clear_bullets()
		stage.FOUR:
			if _health_percent() <= 0.2:
				cur_stage = stage.FIVE
				BOUNCE_BULLET_SPEED += 25
				BURST_NUM_BULLETS -= 2
				SWEEP_FREQ += 0.05
				_attack_reset()
				_clear_bullets()
		stage.FIVE:
			pass

# handle phase-based actions, change phases
func _process_phase(delta):
	phase_timer -= delta
	if phase_timer <= 0:
		match cur_phase:
			phase.BULLET_PHASE:
				cur_phase = phase.ADD_PHASE
				SPAWNER.enabled = true
			phase.ADD_PHASE:
				cur_phase = phase.ADD_TO_BULLET
				SPAWNER.enabled = false
		phase_timer = PHASE_SWITCH_FREQ
		_attack_reset()
	
	if cur_phase == phase.ADD_TO_BULLET and _is_at_point(path_point_center):
		cur_phase = phase.BULLET_PHASE
		phase_timer = PHASE_SWITCH_FREQ
		_clear_enemies()
		

# do attacks for current stage, phase
func _do_attacks(delta):
	if cur_phase == phase.ADD_TO_BULLET:
		return
	
	match cur_stage:
		stage.ONE:
			_stage_one_attack()
		stage.TWO:
			_stage_two_attack()
		stage.THREE:
			_stage_three_attack()
		stage.FOUR:
			_stage_four_attack()
		stage.FIVE:
			_stage_five_attack()

# do movement for current stage, phase
func _do_movement(delta):
	var next_point = _get_next_point() if cur_phase == phase.ADD_PHASE else path_point_center
	if _is_at_point(next_point):
		return
	var move_vector = (next_point - global_position).normalized()
	var collision = move_and_collide(move_vector * delta * SPEED)
	if collision != null:
		if collision.collider == PLAYER:
			_on_collide_with_player(PLAYER)
	_update_move_state(move_vector)
		

# helper for movement
func _get_next_point():
	match next_point:
		path_point.LEFT:
			return path_point_left
		path_point.CENTER:
			return path_point_center
		path_point.RIGHT:
			return path_point_right
		
# helper for movement
func _update_move_state(last_move):
	if _is_at_point(_get_next_point()):
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

func _is_at_point(point, threshold=1):
	return (global_position - point).length() <= threshold

# ==============
#  MAIN ATTACKS
# ==============
func _rotating_burst(duration=ROT_BURST_DURATION):
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

func _twinned_big_shots(angle1, angle2, angle_variance=0):
	if fire_timer > 0:
		return
	angle1 += rng.randf_range(-angle_variance,angle_variance)
	angle2 += rng.randf_range(-angle_variance,angle_variance)
	var bullet1 = _make_big_bullet()
	_shoot_direction(angle1, bullet1, BIG_BULLET_SPEED, soundBasicLaser)
	var bullet2 = _make_big_bullet()
	_shoot_direction(angle2, bullet2, BIG_BULLET_SPEED, soundBasicLaser)
	fire_timer = FIRE_RATE

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

# ===============================
#  STAGE-SPECIFIC ATTACK HELPERS
# ===============================
func _stage_one_attack():
	match cur_phase:
		phase.ADD_PHASE:
			_spaced_bursts(bullets.BASIC)
			_shoot_player(bullets.WHIP)
		phase.BULLET_PHASE:
			_spaced_bursts(bullets.WHIP)
			_shotgun_player(bullets.BASIC)

func _stage_two_attack():
	match cur_phase:
		phase.ADD_PHASE:
			_spaced_bursts(bullets.BASIC)
			_shotgun_player(bullets.WHIP)
		phase.BULLET_PHASE:
			cur_bullet = bullets.WHIP
			_alternating_sweep()
	
func _stage_three_attack():
	match cur_phase:
		phase.ADD_PHASE:
			cur_bullet = bullets.BASIC
			_rotating_burst()
		phase.BULLET_PHASE:
			cur_bullet = bullets.BOUNCE
			_alternating_sweeping_burst()

func _stage_four_attack():
	match cur_phase:
		phase.ADD_PHASE:
			_shoot_player(bullets.HOMING)
		phase.BULLET_PHASE:
			_twinned_big_shots(45,135,20)
			cur_bullet = bullets.BASIC
			_alternating_sweeping_burst()
	
func _stage_five_attack():
	match cur_phase:
		phase.ADD_PHASE:
			cur_bullet = bullets.BASIC
			_alternating_sweep()
			_spaced_bursts(bullets.BOUNCE)
		phase.BULLET_PHASE:
			_twinned_big_shots(0,180)
			cur_bullet = bullets.BOUNCE
			_rotating_burst()

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

func _health_percent():
	return health / MAX_HP

func _attack_reset():
	# stop tweens
	SWEEP_TWEEN.remove_all()
	BURST_TWEEN.remove_all()
	SWEEP_BURST_TWEEN.remove_all()

	# reset timers
	rot_burst_timer = 0
	burst_timer = 0
	sweep_timer = 0
	sweep_burst_timer = 0
	shotgun_timer = 0

func _clear_enemies():
	var root = get_tree().get_root().get_node("World")
	for child in root.get_children():
		if child is Enemy and child != self:
			child.kill()

func _clear_bullets():
	var root = get_tree().get_root().get_node("World")
	for child in root.get_children():
		if child.is_in_group("BossBullet"):
			child.queue_free()
