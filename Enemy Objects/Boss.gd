extends Enemy

signal is_ready

func register_hit(damage):
	health -= damage
	HP.update_hp(health)

func _ready_override():
	_init_hp(MAX_HP)
	yield(HP.TWEEN, "tween_all_completed")
	emit_signal("is_ready")

func _process_override(delta):
	pass

func _physics_process_override(delta):
	pass
	
func _init_hp(max_hp):
	HP = get_tree().get_root().get_node("World").get_node("BossHealthBar")
	HP.show()
	health = max_hp
	HP.set_max(max_hp)
