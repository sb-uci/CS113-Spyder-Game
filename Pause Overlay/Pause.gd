extends Control

func _process(delta):
	if Input.is_action_pressed("ui_cancel"):
		visible = true
		get_tree().paused = true

func _on_restart_pressed():
	get_tree().change_scene("res://World.tscn")
	get_tree().paused = false
	visible = false
	
func _on_continue_pressed():
	get_tree().paused = false
	visible = false

func _on_quit_pressed():
	get_tree().quit()



