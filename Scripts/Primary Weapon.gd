extends Sprite

onready var BULLET = preload("res://Player Objects/Bullet.tscn")
onready var BULLET_SPEED = 300
onready var BULLET_FIRE_RATE = 0.35

var can_shoot = true

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

#Shooting mechanics for player
func _process(delta):
	look_at(get_global_mouse_position())
	if Input.is_action_pressed("shoot") and can_shoot:
		var bullet_instance = BULLET.instance()
		bullet_instance.position = $FiringPoint.get_global_position()
		bullet_instance.rotation_degrees = rotation_degrees
		bullet_instance.apply_impulse(Vector2(), Vector2(BULLET_SPEED, 0).rotated(rotation))
		get_tree().get_root().add_child(bullet_instance)
		can_shoot = false
		yield(get_tree().create_timer(BULLET_FIRE_RATE), "timeout")
		can_shoot = true
