extends "res://Enemy Objects/Enemy Bullet.gd"

export var max_bounces = 2
export var wall_buffer = 5

onready var GLOBALS = get_tree().get_root().get_node("World").get_node("Globals")
onready var left_wall = GLOBALS.cam_center.x - (GLOBALS.cam_width/2) + wall_buffer
onready var right_wall = GLOBALS.cam_center.x + (GLOBALS.cam_width/2) - wall_buffer
onready var top_wall = GLOBALS.cam_center.y - (GLOBALS.cam_height/2) + wall_buffer
onready var bottom_wall = GLOBALS.cam_center.y + (GLOBALS.cam_height/2) - wall_buffer

var bounces = 0

func _process(delta):
	var did_bounce = false
	if global_position.x < left_wall or global_position.x > right_wall:
		linear_velocity *= Vector2(-1,1)
		did_bounce = true
	if global_position.y < top_wall or global_position.y > bottom_wall:
		linear_velocity *= Vector2(1,-1)
		did_bounce = true
	
	if did_bounce:
		global_position += linear_velocity * delta
		rotation = linear_velocity.angle()
		bounces += 1
		if bounces > max_bounces:
			queue_free()
