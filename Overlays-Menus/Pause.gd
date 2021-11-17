extends Control

onready var soundMenuSelect = $MenuSelectSound

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if visible:
			_on_continue_pressed()
		else:
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



