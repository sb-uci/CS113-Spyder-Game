extends Control

export var tween_delay = 0.4
export (Color) var p_healthy_color = Color.green
export (Color) var p_hurt_color = Color.yellow
export (Color) var p_critical_color = Color.red
export (float) var hurt_thresh = 0.5
export (float) var critical_thresh = 0.25
export (Color) var enemy_color = Color.darkred
export var isEnemy = true 

onready var health_bar = $HealthBar
onready var damage_bar = $DamageBar
onready var tween = $Tween

func update_hp(new_hp):
	new_hp *= 100 # scaled for smoother tweening
	health_bar.value = new_hp
	_do_health_tween(new_hp)
	_update_color(new_hp)
	
func set_max(max_hp):
	health_bar.max_value = max_hp * 100 # values scaled for smoother tweening
	damage_bar.max_value = max_hp * 100
	_init_color()

func _do_health_tween(new_hp):
	tween.stop(damage_bar)
	tween.interpolate_property(damage_bar, "value", damage_bar.value, new_hp, 0.4, tween.TRANS_SINE, tween.EASE_IN_OUT, tween_delay)
	tween.start()

func _update_color(new_hp):
	if isEnemy:
		return

	if new_hp < critical_thresh * health_bar.max_value:
		health_bar.tint_progress = p_critical_color
	elif new_hp < hurt_thresh * health_bar.max_value:
		health_bar.tint_progress = p_hurt_color
	else:
		health_bar.tint_progress = p_healthy_color

func _init_color():
	if isEnemy:
		health_bar.tint_progress = enemy_color
	else:
		health_bar.tint_progress = p_healthy_color
