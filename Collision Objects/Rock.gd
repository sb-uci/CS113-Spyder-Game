extends StaticBody2D

onready var default_collision_layer = collision_layer
onready var default_collision_mask = collision_mask

var is_destroyed = false

func destroy():
	$Sprite.visible = false
	collision_layer = 0
	collision_mask = 0
	is_destroyed = true

func rebuild():
	$Sprite.visible = true
	collision_layer = default_collision_layer
	collision_mask = default_collision_mask
	is_destroyed = false
