extends Area2D

export var MOVE_SPEED = 1000

onready var screen_size = get_viewport_rect().size

var EnemyNode
var PlayerNode
var invisMove = true # used to make the indicator make one movement while invisible (it looks better this way)

onready var collision_shape = $CollisionShape2D
onready var xOffset = 160 - collision_shape.shape.extents.x # half screen width - sprite width
onready var yOffset = 90 - collision_shape.shape.extents.y # half screen height - sprite height

func _read():
	visible = false
	global_position = screen_size/2

func set_enemy(enemy):
	EnemyNode = enemy
	PlayerNode = enemy.PLAYER
	global_position = PlayerNode.global_position

func _process(delta):
	if invisMove:
		_do_movement(1)
		visible = true
		invisMove = false
	else:
		_do_movement(delta)
		

func _do_movement(delta):
	var camX = PlayerNode.global_position.x
	var camY = PlayerNode.global_position.y
	
	var movement = EnemyNode.global_position - global_position
	movement = movement.normalized()
	rotation_degrees = (movement.angle() * 180/PI) + 90
	
	position += movement * delta * MOVE_SPEED
	position.x = clamp(position.x, camX - xOffset, camX + xOffset)
	position.y = clamp(position.y, camY - yOffset, camY + yOffset)
