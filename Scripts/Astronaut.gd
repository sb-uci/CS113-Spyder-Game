extends KinematicBody2D

export var MAX_SPEED = 150
export var ACCELERATION = 450
export var FRICTION = 650
export var MAX_HP = 5
export var INVULN_TIME = 1.5
export var FLASH_FREQ = .15

var velocity = Vector2.ZERO
var health = MAX_HP
var is_invuln = false
var invuln_timer
var flash_timer

onready var health_bar = $HealthBar
onready var sprite = $Sprite
onready var weapon = $"Primary Weapon"
onready var tween = $Tween
#onready var animationPlayer = $AnimationPlayer

func damage_player(damage):
	if is_invuln:
		return
	health -= damage # do damage
	health_bar.update_hp(health) # update health bar
	 # trigger invuln
	is_invuln = true
	invuln_timer = INVULN_TIME
	# trigger invuln flash
	flash_timer = FLASH_FREQ
	_flash_sprite(sprite, Color(1,1,1,0), tween.EASE_OUT)
	_flash_sprite(weapon, Color(1,1,1,0), tween.EASE_OUT)

func _ready():
	_init_hp()

#Movement for player
func _physics_process(delta):
	_do_movement(delta)

func _process(delta):
	_handle_invuln(delta)
	
func _do_movement(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		#animationPlayer.play("RunDown")
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		#animationPlayer.play("idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	velocity = move_and_slide(velocity)

func _handle_invuln(delta):
	if is_invuln:
		_invuln_flash(delta)
		invuln_timer -= delta
		if invuln_timer <= 0:
			is_invuln = false
			_cancel_flash()

func _invuln_flash(delta):
	flash_timer -= delta
	if flash_timer <= 0:
		tween.stop(sprite)
		tween.stop(weapon)
		
		if sprite.modulate == Color(1,1,1,0):
			print("undoing flash")
			_flash_sprite(sprite, Color(1,1,1,1), tween.EASE_IN)
			_flash_sprite(weapon, Color(1,1,1,1), tween.EASE_IN)
		else:
			print("flashing")
			_flash_sprite(sprite, Color(1,1,1,0), tween.EASE_OUT)
			_flash_sprite(weapon, Color(1,1,1,0), tween.EASE_OUT)
		
		flash_timer = FLASH_FREQ + flash_timer # reset and add any overflow

func _cancel_flash():
	tween.stop(sprite)
	tween.stop(weapon)
	sprite.modulate = Color(1,1,1,1)
	weapon.modulate = Color(1,1,1,1)

func _flash_sprite(sprite_node, color_state, easing):
	tween.interpolate_property(sprite_node, "modulate", sprite_node.modulate, color_state, 
	FLASH_FREQ, tween.TRANS_LINEAR, easing)
	tween.start()
	
func _init_hp():
	health_bar.set_max(MAX_HP)
	health_bar.update_hp(MAX_HP)
