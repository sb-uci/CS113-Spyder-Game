extends Control

onready var soundGameOver = $GameOverSound
onready var soundHurt = $HurtSound
onready var soundMenuSelect = $MenuSelectSound

func _ready():
	soundHurt.play()
	soundGameOver.play()

func _on_Play_Again_pressed():
	soundMenuSelect.play()
	get_tree().change_scene("res://World.tscn")

func _on_Quit_pressed():
	soundMenuSelect.play()
	get_tree().quit()
