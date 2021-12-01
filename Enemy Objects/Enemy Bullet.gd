extends RigidBody2D

export var offscreen_immunity = 1 # seconds before going offscreen will cause dequeue
export var lifetime = 10 # seconds before forced dequeue

var damage

func _process_override(delta):
	offscreen_immunity -= delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	if !_is_on_screen() and offscreen_immunity <= 0:
		queue_free()

func _process(delta):
	_process_override(delta)

func _on_Enemy_Bullet_body_entered(body):
	if body.is_in_group("Player"):
		body.damage_player(damage)
	elif body.is_in_group("Bullet") or body.is_in_group("Boss"):
		return
	queue_free()

func _is_on_screen():
	var x_low = GLOBALS.cam_center.x - GLOBALS.cam_width/2
	var x_high = GLOBALS.cam_center.x + GLOBALS.cam_width/2
	var y_low = GLOBALS.cam_center.y - GLOBALS.cam_height/2
	var y_high = GLOBALS.cam_center.y + GLOBALS.cam_height/2
	
	var is_in_x_bound = global_position.x >= x_low and global_position.x <= x_high
	var is_in_y_bound = global_position.y >= y_low and global_position.y <= y_high
	return is_in_x_bound and is_in_y_bound
