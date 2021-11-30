extends Control

onready var MainMenu = get_parent().get_node("Main")
onready var soundMenuSelect = get_parent().get_node("MenuSelectSound")

func _ready():
	visible = false

func _on_Main_Menu_pressed():
	soundMenuSelect.play()
	visible = false
	MainMenu.visible = true
