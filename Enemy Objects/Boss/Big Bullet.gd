extends "res://Enemy Objects/Enemy Bullet.gd"

export var BURST_NUM_BULLETS = 10
export var BURST_BULLET_SPEED = 100
export var BURST_DAMAGE = 1
export var BURST_BULLET = preload("res://Enemy Objects/Boss/Basic Bullet.tscn")

onready var soundBurst = $BurstSound
onready var GLOBALS = get_tree().get_root().get_node("World").get_node("Globals")

func _process(delta):
	if !_is_on_screen():
		_death_burst()
		queue_free()

func _on_Enemy_Bullet_body_entered(body):
	if body.is_in_group("Player"):
		body.damage_player(damage)
	elif body.is_in_group("Bullet") or body.is_in_group("Boss"):
		return
	elif body.is_in_group("CollisionObject"):
		_destroy(body)
	queue_free()

func _death_burst():
	var direction = 0
	for i in range(BURST_NUM_BULLETS):
		var bullet = BURST_BULLET.instance()
		bullet.damage = BURST_DAMAGE
		bullet.position = global_position
		bullet.rotation_degrees = direction
		bullet.apply_impulse(Vector2(), Vector2(BURST_BULLET_SPEED, 0).rotated(direction * PI/180))
		get_tree().get_root().get_node("World").add_child(bullet)
		soundBurst.play()
		direction += 360/BURST_NUM_BULLETS

func _is_on_screen():
	var x_low = GLOBALS.cam_center.x - GLOBALS.cam_width/2
	var x_high = GLOBALS.cam_center.x + GLOBALS.cam_width/2
	var y_low = GLOBALS.cam_center.y - GLOBALS.cam_height/2
	var y_high = GLOBALS.cam_center.y + GLOBALS.cam_height/2
	
	var is_in_x_bound = global_position.x >= x_low and global_position.x <= x_high
	var is_in_y_bound = global_position.y >= y_low and global_position.y <= y_high
	return is_in_x_bound and is_in_y_bound

# because of the obstacle-nesting solution for navmesh polygon joining,
# simply destroying an obstacle will destroy any nested obstacles.
# Instead, those should be reparented
func _destroy(collision_object):
	var has_seen_first_child = false
	var new_parent = collision_object.get_parent()
	for child in collision_object.get_children():
		if child.is_in_group("CollisionObject"):
			# gather parent transform data
			var new_pos = child.global_position
			var parent_scale = collision_object.scale
			
			# reparent
			child.name += "%{id}".format({"id" : GLOBALS.reparent_counter})
			GLOBALS.reparent_counter += 1
			collision_object.remove_child(child)
			new_parent.add_child(child)
			
			# apply parent transform
			child.global_position = new_pos
			child.scale *= parent_scale
			
			if !has_seen_first_child:
				new_parent = child
				has_seen_first_child = true
	collision_object.queue_free()
