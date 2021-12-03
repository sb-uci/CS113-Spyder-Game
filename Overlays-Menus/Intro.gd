extends Node2D


func menu_transition():
	get_tree().change_scene("res://World.tscn")

func _on_AnimationPlayer_animation_finished(anim_name):
	menu_transition()
