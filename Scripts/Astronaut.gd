extends KinematicBody2D

const FixedStack = preload("res://Scripts/FixedStack.gd")

export var MAX_SPEED = 150
export var ACCELERATION = 450
export var FRICTION = 650
export var MAX_HP = 5
export var INVULN_TIME = 1.5
export var FLASH_FREQ = .15
export var KNOCKBACK_RESISTANCE = 1.1 # how quickly the astronaut recovers from (1 is no resistance)
export var MOVEMENT_AVERAGE = 1 # length of history of previous movements

export var design_width = 320 # design resolution; different from real resolution
export var design_height = 180

var DEFAULT_MASK = 0b00000000000001010110
var INVULN_MASK =  0b00000000000001000010

var velocity = Vector2.ZERO
var health = MAX_HP
var is_invuln = false
var invuln_timer
var flash_timer
var impulses = []

onready var HEALTH_BAR = $HealthBar
onready var SPRITE = $Sprite
onready var WEAPON = $"Primary Weapon"
onready var TWEEN = $Tween
onready var recent_movement = FixedStack.new()

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")

func damage_player(damage):
	if is_invuln:
		return
	health -= damage # do damage
	HEALTH_BAR.update_hp(health) # update health bar
	 # trigger invuln
	is_invuln = true
	invuln_timer = INVULN_TIME
	self.collision_mask = INVULN_MASK
	self.collision_layer = 128
	# trigger invuln flash
	flash_timer = FLASH_FREQ
	_flash_sprite(SPRITE, Color(1,1,1,0), TWEEN.EASE_OUT)
	_flash_sprite(WEAPON, Color(1,1,1,0), TWEEN.EASE_OUT)
	
func get_collision_center():
	var collision_shape = $CollisionShape2D
	return collision_shape.global_position
	
func get_velocity():
	var average = Vector2()
	for i in range(recent_movement.size()):
		average += recent_movement.get(i)
	return average / MOVEMENT_AVERAGE

func set_speed(new_speed):
	MAX_SPEED = new_speed

func set_fire_rate(fire_rate_increase):
	var weaponInstance = get_node("Primary Weapon")
	weaponInstance.BULLET_FIRE_RATE /= fire_rate_increase
	
func apply_pseudo_impulse(direction, force):
	direction = direction.normalized()
	var impulse = direction * force
	impulses.append(impulse)

func can_see_point(point):
	var x_low = global_position.x - design_width/2
	var x_high = global_position.x + design_width/2
	var y_low = global_position.y - design_height/2
	var y_high = global_position.y + design_height/2
	
	var is_in_x_bound = point.x >= x_low and point.x <= x_high
	var is_in_y_bound = point.y >= y_low and point.y <= y_high
	return is_in_x_bound and is_in_y_bound

func _ready():
	_init_hp()
	recent_movement.set_size(MOVEMENT_AVERAGE)

#Movement for player
func _physics_process(delta):
	_do_movement(delta)
	_handle_impulses(delta)

func _process(delta):
	_handle_invuln(delta)
	
func _do_movement(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationState.travel("Run")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	velocity = move_and_slide(velocity)
	recent_movement.append(velocity)

func _handle_impulses(delta):
	var pop_list = [] # used to remove impulses without modifying list during main loop
	for i in impulses.size():
		move_and_collide(impulses[i] * delta)
		impulses[i] /= KNOCKBACK_RESISTANCE
		if impulses[i].length() <= 1:
			pop_list.append(i)
	
	for i in pop_list:
		impulses.remove(i)

func _handle_invuln(delta):
	if is_invuln:
		_invuln_flash(delta)
		invuln_timer -= delta
		if invuln_timer <= 0:
			is_invuln = false
			self.collision_mask = DEFAULT_MASK
			self.collision_layer = 1
			_cancel_flash()

func _invuln_flash(delta):
	flash_timer -= delta
	if flash_timer <= 0:
		TWEEN.stop(SPRITE)
		TWEEN.stop(WEAPON)
		
		if SPRITE.modulate == Color(1,1,1,0):
			_flash_sprite(SPRITE, Color(1,1,1,1), TWEEN.EASE_IN)
			_flash_sprite(WEAPON, Color(1,1,1,1), TWEEN.EASE_IN)
		else:
			_flash_sprite(SPRITE, Color(1,1,1,0), TWEEN.EASE_OUT)
			_flash_sprite(WEAPON, Color(1,1,1,0), TWEEN.EASE_OUT)
		
		flash_timer = FLASH_FREQ + flash_timer # reset and add any overflow

func _cancel_flash():
	TWEEN.stop(SPRITE)
	TWEEN.stop(WEAPON)
	SPRITE.modulate = Color(1,1,1,1)
	WEAPON.modulate = Color(1,1,1,1)

func _flash_sprite(sprite_node, color_state, easing):
	TWEEN.interpolate_property(sprite_node, "modulate", sprite_node.modulate, color_state, 
	FLASH_FREQ, TWEEN.TRANS_LINEAR, easing)
	TWEEN.start()
	
func _init_hp():
	HEALTH_BAR.set_max(MAX_HP)
	HEALTH_BAR.update_hp(MAX_HP)
	
