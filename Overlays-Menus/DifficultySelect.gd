extends Control

onready var ProgressController = get_tree().get_root().get_node("World").get_node("ProgressController")
onready var soundMenuSelect = get_parent().get_node("MenuSelectSound")

func _ready():
	visible = false

func _on_Easy_pressed():
	soundMenuSelect.play()
	ProgressController.start(0)
	visible= false

func _on_Medium_pressed():
	soundMenuSelect.play()
	ProgressController.start(1)
	visible = false

func _on_Hard_pressed():
	soundMenuSelect.play()
	ProgressController.start(2)
	visible = false
