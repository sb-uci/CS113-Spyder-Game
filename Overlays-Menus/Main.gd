extends Control

onready var DifficultyMenu = get_parent().get_node("DifficultySelect")

func _ready():
	visible = true

func _on_Start_pressed():
	visible = false
	DifficultyMenu.visible = true

func _on_Credits_pressed():
	pass # Replace with function body.


func _on_Quit_pressed():
	get_tree().quit()
