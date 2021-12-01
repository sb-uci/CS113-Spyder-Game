extends Control

onready var DifficultyMenu = get_parent().get_node("DifficultySelect")
onready var CreditsMenu = get_parent().get_node("Credits")
onready var soundMenuSelect = get_parent().get_node("MenuSelectSound")

func _ready():
	if GLOBALS.isBossReached:
		return
	visible = true

func _on_Start_pressed():
	soundMenuSelect.play()
	visible = false
	DifficultyMenu.visible = true

func _on_Credits_pressed():
	soundMenuSelect.play()
	visible = false
	CreditsMenu.visible = true


func _on_Quit_pressed():
	soundMenuSelect.play()
	get_tree().quit()
