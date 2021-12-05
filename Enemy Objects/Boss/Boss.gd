extends "res://Enemy Objects/Shooting Enemy.gd"

signal is_ready

enum stage {ONE, TWO, THREE, FOUR, FIVE}
enum phase {BULLET_PHASE, ADD_PHASE, ADD_TO_BULLET}
enum path_point {CENTER, LEFT, RIGHT}
enum sweep_dir {LEFT, RIGHT}
enum bullets {BASIC, BIG, WHIP, HOMING, BOUNCE}
enum difficulty_level {EASY, MEDIUM, HARD}

# INNATE BULLET PROPERTIES
export var BASIC_BULLET_DAMAGE = 1.0
export var BASIC_BULLET_SPEED = 175
export var BASIC_BULLET = preload("res://Enemy Objects/Boss/Basic Bullet.tscn")
export var BIG_BULLET_DAMAGE = 2.0
export var BIG_BULLET_SPEED = 100
export var BIG_BULLET = preload("res://Enemy Objects/Boss/Big Bullet.tscn")
export var WHIP_BULLET_DAMAGE = 1.0
export var WHIP_BULLET_SPEED = 20
export var WHIP_BULLET = preload("res://Enemy Objects/Boss/Whip Bullet.tscn")
export var HOMING_BULLET_DAMAGE = 1.0
export var HOMING_BULLET_SPEED = 65
export var HOMING_BULLET = preload("res://Enemy Objects/Boss/Homing Bullet.tscn")
export var BOUNCE_BULLET_DAMAGE = 1.0
export var BOUNCE_BULLET_SPEED = 125
export var BOUNCE_BULLET = preload("res://Enemy Objects/Boss/Bouncing Bullet.tscn")

# ATTACK TIMING (higher is slower/easier)
export var BURST_DELAY = 1
export var ROT_BURST_DELAY = .4
export var SWEEP_BURST_DELAY = .1
export var SWEEP_DELAY = .1
export var SHOTGUN_DELAY = 1
export var WAVE_DELAY = 1

# ATTACK QUANTITY
export var BURST_NUM_BULLETS = 8
export var ROT_BURST_NUM_BULLETS = 10
export var SWEEP_BURST_NUM_BULLETS = 10
export var SHOTGUN_NUM_BULLETS = 6
export var WAVE_NUM_BULLETS = 7

# ATTACK DURATION
export var SWEEP_DURATION = .75 # smaller is easier
export var ROT_BURST_DURATION = 3 # doesn't actually matter, I think
export var SWEEP_BURST_DURATION = 1 # smaller is harder

# OTHER ATTACK PROPERTIES
export var SHOTGUN_SPREAD = 20 # bigger is harder, until it's not
export var SHOTGUN_VARIANCE_RATIO = 4 # bigger is easier (less variance)

# MISC TIMING
export var PHASE_SWITCH_FREQ = 10 # how long boss spends in each phase (NOT stage)

# ENUM DEFAULTS
onready var cur_phase = phase.ADD_PHASE
onready var cur_stage = stage.ONE
onready var sweep_state = sweep_dir.LEFT
onready var sweep_burst_state = sweep_dir.LEFT
onready var cur_bullet = bullets.BASIC
onready var difficulty = difficulty_level.MEDIUM

# MOVEMENT DEFAULTS
onready var next_point = path_point.LEFT
onready var path_point_center = global_position
onready var path_point_left = global_position - Vector2(100,-50)
onready var path_point_right = global_position + Vector2(100,50)

# SOUNDS
onready var soundBasicLaser = $BasicLaserSound
onready var soundDeath = $DeathSound

# TWEENS
onready var SWEEP_TWEEN = $SweepTween
onready var BURST_TWEEN = $BurstTween
onready var SWEEP_BURST_TWEEN = $SweepingBurstTween
onready var CASCADING_TWEEN = $CascadingTween

# MISC
onready var SPAWNER = get_tree().get_root().get_node("World").get_node("Spawner")
onready var PROGRESS_CONTROLLER = get_tree().get_root().get_node("World").get_node("ProgressController")

# SPRITE
onready var SPRITE = $AnimatedSprite

# PROPERTIES
var phase_timer = PHASE_SWITCH_FREQ
var rot_burst_timer = 0
var burst_timer = 0
var sweep_timer = 0
var sweep_burst_timer = 0
var shotgun_timer = 0
var rng = RandomNumberGenerator.new()
var alive = true

func set_difficulty(difficulty_num):
	match difficulty_num:
		0:
			difficulty = difficulty_level.EASY
		1:
			difficulty = difficulty_level.MEDIUM
		2:
			difficulty = difficulty_level.HARD
	_global_difficulty_adjustment()

# call to damage the boss
func register_hit(damage):
	if alive:
		health -= damage
		HP.update_hp(health)
		if health <= 0:
			_death()

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
	if alive:
		_process_stage()
		_process_phase(delta)
		_do_movement(delta)
		_do_attacks(delta)
		_elapse_timers(delta)
	else:
		SPRITE.play("idle_front")

# overrides the _physics_process() method body in parent class
func _physics_process_override(delta):
	if alive and _detect_player_collision(PLAYER):
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
				_one_to_two_difficulty_adjustment()
				_do_stage_transition()
		stage.TWO:
			if _health_percent() <= 0.6:
				cur_stage = stage.THREE
				_two_to_three_difficulty_adjustment()
				_do_stage_transition()
		stage.THREE:
			if _health_percent() <= 0.4:
				cur_stage = stage.FOUR
				_three_to_four_difficulty_adjustment()
				_do_stage_transition()
		stage.FOUR:
			if _health_percent() <= 0.2:
				cur_stage = stage.FIVE
				_four_to_five_difficulty_adjustment()
				_do_stage_transition()
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
				if cur_stage == stage.FOUR:
					_clear_bullets()
		phase_timer = PHASE_SWITCH_FREQ
		_attack_reset()
	
	if cur_phase == phase.ADD_TO_BULLET and _is_at_point(path_point_center):
		cur_phase = phase.BULLET_PHASE
		phase_timer = PHASE_SWITCH_FREQ
		_clear_enemies()
		SPRITE.play("idle_front")
		

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
	SPRITE.play("move")
	SPRITE.flip_h = move_vector.x < 0

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

func _shoot_player(bullet_type, cooldown=FIRE_RATE, angle_offset=0):
	if fire_timer > 0:
		return
	var bullet = _make_bullet(bullet_type)
	_shoot_target(PLAYER, bullet[0], bullet[1], soundBasicLaser, angle_offset)
	fire_timer = cooldown

func _shotgun_player(bullet_type, cooldown=SHOTGUN_DELAY):
	if shotgun_timer > 0:
		return
	_shotgun(PLAYER, bullet_type)
	shotgun_timer = cooldown

func _spaced_bursts(bullet_type, cooldown=BURST_DELAY):
	if burst_timer > 0:
		return
	_burst(BURST_NUM_BULLETS, 0, 0, bullet_type)
	burst_timer = cooldown

func _twinned_shots(bullet_type, angle1, angle2, angle_variance=0, cooldown=FIRE_RATE):
	if fire_timer > 0:
		return
	angle1 += rng.randf_range(-angle_variance,angle_variance)
	angle2 += rng.randf_range(-angle_variance,angle_variance)
	var bullet1 = _make_bullet(bullet_type)
	_shoot_direction(angle1, bullet1[0], bullet1[1], soundBasicLaser)
	var bullet2 = _make_bullet(bullet_type)
	_shoot_direction(angle2, bullet2[0], bullet1[1], soundBasicLaser)
	fire_timer = cooldown

func _wave_at_player(bullet_type):
	var offset_half = (WAVE_NUM_BULLETS/2) * 15
	for i in range(WAVE_NUM_BULLETS-1):
		_shoot_player(bullet_type, 0, (i*15)-offset_half)
	_shoot_player(bullets.BASIC, WAVE_DELAY, ((WAVE_NUM_BULLETS-1)*15)-offset_half)

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
	var speed_variance = bullet[1]/SHOTGUN_VARIANCE_RATIO
	bullet[0].queue_free()
	
	for i in range(num_bullets):
		var angle_offset = rng.randf_range(-spread/2, spread/2)
		var speed_offset = rng.randf_range(-speed_variance/2, speed_variance/2)
		_shoot_direction(direction + angle_offset, _make_bullet(bullet_type)[0], bullet_speed + speed_offset, soundBasicLaser)

func _shoot_target(target, bullet, speed, sound, angle_offset=0):
	var radian_offset = angle_offset * PI/180
	var direction = (target.global_position - global_position).angle()
	bullet.rotation_degrees = (direction * 180/PI) + angle_offset
	bullet.apply_impulse(Vector2(), Vector2(speed, 0).rotated(direction + radian_offset))
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
	sweep_timer = SWEEP_DELAY

func _rotate_burst_wrapper(offset):
	if rot_burst_timer > 0:
		return
	_burst(ROT_BURST_NUM_BULLETS, offset, -50)
	rot_burst_timer = ROT_BURST_DELAY

func _sweeping_burst_wrapper(offset):
	if sweep_burst_timer > 0:
		return
	_burst(SWEEP_BURST_NUM_BULLETS, offset, -50)
	sweep_burst_timer = SWEEP_BURST_DELAY

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
			if phase_timer < 8:
				_shotgun_player(bullets.BASIC)
		phase.BULLET_PHASE:
			cur_bullet = bullets.BASIC
			_alternating_sweep()
			if difficulty == difficulty_level.HARD:
				_shoot_player(bullets.BOUNCE, .5)
			else:
				if !CASCADING_TWEEN.is_active() and fire_timer <= 0:
					_shoot_player(bullets.BOUNCE, 0)
					CASCADING_TWEEN.interpolate_callback(self, .33, "_shoot_player", bullets.BOUNCE, 0)
					CASCADING_TWEEN.interpolate_callback(self, .67, "_shoot_player", bullets.BOUNCE)
					CASCADING_TWEEN.start()
		
func _stage_three_attack():
	match cur_phase:
		phase.ADD_PHASE:
			cur_bullet = bullets.BASIC
			_rotating_burst()
		phase.BULLET_PHASE:
			cur_bullet = bullets.BOUNCE
			_alternating_sweeping_burst()
			if difficulty == difficulty_level.HARD:
				_rotating_burst()

func _stage_four_attack():
	match cur_phase:
		phase.ADD_PHASE:
			if phase_timer < 8:
				_wave_at_player(bullets.BASIC)
		phase.BULLET_PHASE:
			_twinned_shots(bullets.BIG,45,135,20)
			cur_bullet = bullets.BASIC
			_alternating_sweeping_burst()
	
func _stage_five_attack():
	match cur_phase:
		phase.ADD_PHASE:
			cur_bullet = bullets.BASIC
			_alternating_sweep()
			_spaced_bursts(bullets.BOUNCE)
		phase.BULLET_PHASE:
			_twinned_shots(bullets.BIG,0,180,0,0)
			_twinned_shots(bullets.BASIC,45,135)
			cur_bullet = bullets.BOUNCE
			_rotating_burst()

# ===============================
#  DIFFICULTY ADJUSTMENT HELPERS
# ===============================
func _global_difficulty_adjustment():
	match difficulty:
		difficulty_level.EASY:
			BASIC_BULLET_DAMAGE /= 2
			BIG_BULLET_DAMAGE /= 2
			WHIP_BULLET_DAMAGE /= 2
			HOMING_BULLET_DAMAGE /= 2
			BOUNCE_BULLET_DAMAGE /= 2
		difficulty_level.MEDIUM:
			pass
		difficulty_level.HARD:
			BURST_NUM_BULLETS += 4
			BURST_DELAY -= .2
			ROT_BURST_NUM_BULLETS += 4
			ROT_BURST_DELAY -= .05
			WAVE_NUM_BULLETS += 4

func _one_to_two_difficulty_adjustment():
	match difficulty:
		difficulty_level.EASY:
			pass
		difficulty_level.MEDIUM:
			BURST_NUM_BULLETS += 2
		difficulty_level.HARD:
			BURST_NUM_BULLETS += 4

func _two_to_three_difficulty_adjustment():
	BURST_DELAY += 0.25
	BURST_NUM_BULLETS -= 2
	SWEEP_BURST_DELAY += 0.05
	match difficulty:
		difficulty_level.EASY:
			pass
		difficulty_level.MEDIUM:
			pass
		difficulty_level.HARD:
			BURST_NUM_BULLETS += 2
			BURST_DELAY -= 0.25
	
func _three_to_four_difficulty_adjustment():
	SHOTGUN_SPREAD += 35
	SHOTGUN_VARIANCE_RATIO += 10
	match difficulty:
		difficulty_level.EASY:
			SHOTGUN_NUM_BULLETS -= 4
		difficulty_level.MEDIUM:
			SWEEP_BURST_DELAY -= 0.05
		difficulty_level.HARD:
			BASIC_BULLET_SPEED -= 50
	
func _four_to_five_difficulty_adjustment():
	BOUNCE_BULLET_SPEED += 25
	BURST_NUM_BULLETS -= 2
	match difficulty:
		difficulty_level.EASY:
			pass
		difficulty_level.MEDIUM:
			pass
		difficulty_level.HARD:
			BASIC_BULLET_SPEED += 50

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
			if child.health == child.MAX_HP:
				child.kill()

func _clear_bullets():
	var root = get_tree().get_root().get_node("World")
	for child in root.get_children():
		if child.is_in_group("BossBullet"):
			child.queue_free()

func _do_stage_transition():
	_attack_reset()
	_clear_bullets()

func _death():
	$ScreenFlash.flash()
	soundDeath.play()
	alive = false
	PROGRESS_CONTROLLER.end_game()
