extends Sprite

onready var BULLET = preload("res://Player Objects/Bullet.tscn")
onready var BULLET_SPEED = 300
onready var BULLET_FIRE_RATE = 0.35
onready var BULLET_DAMAGE = 1

var can_shoot = true
var direction = "Right"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

#Shooting mechanics for player
func _process(delta):
	rotate_sprite()
	if Input.is_action_pressed("shoot") and can_shoot:
		var bullet_instance = BULLET.instance()
		bullet_instance.damage = BULLET_DAMAGE
		bullet_instance.position = $FiringPoint.get_global_position()
		bullet_instance.rotation_degrees = rotation_degrees
		bullet_instance.apply_impulse(Vector2(), Vector2(BULLET_SPEED, 0).rotated(rotation))
		get_tree().get_root().add_child(bullet_instance)
		can_shoot = false
		yield(get_tree().create_timer(BULLET_FIRE_RATE), "timeout")
		can_shoot = true

# Rotate gun sprite
func rotate_sprite():
	var mouse_pos = get_global_mouse_position()
	look_at(mouse_pos)
	
	if direction == "Right" and mouse_pos.x < self.global_position.x:
		self.set_flip_v(true)
		direction = "Left"
	elif direction == "Left" and mouse_pos.x > self.global_position.x:
		self.set_flip_v(false)
		direction = "Right"
