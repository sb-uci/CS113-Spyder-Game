extends KinematicBody2D

export var MAX_SPEED = 150
export var ACCELERATION = 450
export var FRICTION = 650
export var MAX_HP = 5

var velocity = Vector2.ZERO
var health = MAX_HP

onready var health_bar = $HealthBar
#onready var animationPlayer = $AnimationPlayer

func _ready():
	_init_hp()

#Movement for player
func _physics_process(delta):
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

#func _process(delta):
#	pass
	

func _init_hp():
	health_bar.set_max(MAX_HP)
	health_bar.update_hp(MAX_HP)
