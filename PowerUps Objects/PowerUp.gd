extends Node

class_name PowerUp

export var POWERUP_DURATION = 5

var lifetime = POWERUP_DURATION
var powerUpTimer = null
var instanceTimer = null

onready var PLAYER = get_parent().get_node("Astronaut")

func _ready():
	self._create_instance_timer()

func _create_instance_timer():
	instanceTimer = Timer.new()
	instanceTimer.set_one_shot(true)
	instanceTimer.set_wait_time(POWERUP_DURATION)
	instanceTimer.connect("timeout", self, "_on_instance_timeout")
	add_child(instanceTimer)
	instanceTimer.start()
	
func _create_powerUp_timer():
	powerUpTimer = Timer.new()
	powerUpTimer.set_one_shot(true)
	powerUpTimer.set_wait_time(POWERUP_DURATION)
	powerUpTimer.connect("timeout", self, "_on_powerup_timeout")
	add_child(powerUpTimer)
	powerUpTimer.start()

func _on_instance_timeout():
	queue_free()

func _on_powerup_timeout():
	pass

func _flash_sprite(sprite, tween, freq=.35):
	if powerUpTimer == null and !tween.is_active():
		var cur_color = sprite.modulate
		var next_color = Color(1,1,1,0) if cur_color == Color(1,1,1,1) else Color(1,1,1,1)
		tween.interpolate_property(sprite, "modulate", cur_color, next_color, freq, tween.TRANS_LINEAR, tween.EASE_IN_OUT)
		tween.start()
