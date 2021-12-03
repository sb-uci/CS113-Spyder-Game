extends Control

onready var TEXTBOX = get_tree().get_root().get_node("World").get_node("TextBoxOverlay")

func _ready():
	visible = false
	$Label.modulate = Color(1,1,1,0)

func switch_to():
	$Tween.interpolate_property($ColorRect, "modulate", Color(1,1,1,0), Color(1,1,1,1), 2, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()
	visible = true
	yield(TEXTBOX, "has_become_inactive")
	$Tween.interpolate_property($Label, "modulate", Color(1,1,1,0), Color(1,1,1,1), 5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
