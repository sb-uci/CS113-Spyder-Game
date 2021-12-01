extends Control

onready var soundGameOver = $GameOverSound
onready var soundHurt = $HurtSound
onready var soundMenuSelect = $MenuSelectSound

func activate():
	soundHurt.play()
	soundGameOver.play()
	visible = true

func _on_Play_Again_pressed():
	soundMenuSelect.play()
	if GLOBALS.isBossReached:
		visible = false
		get_tree().get_root().get_node("World").get_node("ProgressController").start(GLOBALS.difficulty)
	else:
		get_tree().change_scene("res://World.tscn")

func _on_Quit_pressed():
	soundMenuSelect.play()
	get_tree().quit()
