extends KinematicBody2D

var speed = 100
onready var player = get_parent().get_node("Astronaut")

func _physics_process(delta):
	var dir = (player.global_position - global_position).normalized()
	move_and_collide(dir * speed * delta)
