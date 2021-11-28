extends Area2D

export var MOVE_SPEED = 1000

onready var GLOBALS = get_tree().get_root().get_node("World").get_node("Globals")
onready var collision_shape = $CollisionShape2D

var EnemyNode
var PlayerNode
var invisMove = true # used to make the indicator make one movement while invisible (it looks better this way)
var xOffset
var yOffset
var screen_size

func _ready():
	set_offsets()
	visible = false
	global_position = GLOBALS.cam_center

func set_enemy(enemy):
	EnemyNode = enemy
	PlayerNode = enemy.PLAYER
	global_position = PlayerNode.global_position
	screen_size = get_viewport_rect().size
	
func set_offsets():
	xOffset = (GLOBALS.cam_width/2) - collision_shape.shape.extents.x # half screen width - sprite width
	yOffset = (GLOBALS.cam_height/2) - collision_shape.shape.extents.y # half screen height - sprite height

func _process(delta):
	if invisMove:
		_do_movement(1)
		visible = true
		invisMove = false
	else:
		_do_movement(delta)
		

func _do_movement(delta):
	var movement = EnemyNode.global_position - global_position
	movement = movement.normalized()
	rotation_degrees = (movement.angle() * 180/PI) + 90
	
	position += movement * delta * MOVE_SPEED
	position.x = clamp(position.x, GLOBALS.cam_center.x - xOffset, GLOBALS.cam_center.x + xOffset)
	position.y = clamp(position.y, GLOBALS.cam_center.y - yOffset, GLOBALS.cam_center.y + yOffset)
