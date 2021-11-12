extends Control

onready var ProgressController = get_tree().get_root().get_node("World").get_node("ProgressController")

func _ready():
	visible = false

func _on_Easy_pressed():
	ProgressController.start(0)
	visible= false

func _on_Medium_pressed():
	ProgressController.start(1)
	visible = false

func _on_Hard_pressed():
	ProgressController.start(2)
	visible = false
