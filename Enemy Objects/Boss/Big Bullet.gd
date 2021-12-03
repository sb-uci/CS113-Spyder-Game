extends "res://Enemy Objects/Enemy Bullet.gd"

export var BURST_NUM_BULLETS = 10
export var BURST_BULLET_SPEED = 100
export var BURST_DAMAGE = 1
export var BURST_BULLET = preload("res://Enemy Objects/Boss/Basic Bullet.tscn")

onready var soundBurst = $BurstSound
onready var NAVIGATION = get_tree().get_root().get_node("World").get_node("Navigation")

func _process_override(delta):
	lifetime -= delta
	if lifetime <= 0:
		_death_burst()
		queue_free()
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

# because of the obstacle-nesting solution for navmesh polygon joining,
# simply destroying an obstacle will destroy any nested obstacles.
# Instead, those should be reparented
func _destroy(collision_object):
	collision_object.destroy()
	NAVIGATION.rebake_mesh()
	return
