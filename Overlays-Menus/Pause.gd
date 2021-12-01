extends Control

onready var soundMenuSelect = $MenuSelectSound
onready var player = get_tree().get_root().get_node("World").get_node("Astronaut")
onready var mainMenu = get_tree().get_root().get_node("World").get_node("MainMenu")

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if visible:
			_on_continue_pressed()
		else:
			if _is_in_main_menu():
				return
			visible = true
			get_tree().paused = true

func _on_restart_pressed():
	soundMenuSelect.play()
	get_tree().change_scene("res://World.tscn")
	get_tree().paused = false
	visible = false
	
func _on_continue_pressed():
	soundMenuSelect.play()
	get_tree().paused = false
	visible = false

func _on_quit_pressed():
	soundMenuSelect.play()
	get_tree().quit()

func _on_godmode_pressed():
	soundMenuSelect.play()
	player.HAS_GODMODE = !player.HAS_GODMODE
	get_tree().paused = false
	visible = false

func _is_in_main_menu():
	var main = mainMenu.get_node("Main")
	var credits = mainMenu.get_node("Credits")
	var difficulty_menu = mainMenu.get_node("DifficultySelect")
	return main.visible or credits.visible or difficulty_menu.visible
