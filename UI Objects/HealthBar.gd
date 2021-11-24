extends Control

export var TWEEN_DELAY = 0.4
export (Color) var P_HEALTHY_COLOR = Color.green
export (Color) var P_HURT_COLOR = Color.yellow
export (Color) var P_CRITICAL_COLOR = Color.red
export (float) var HURT_THRESH = 0.5
export (float) var CRITICAL_THRESH = 0.25
export (Color) var ENEMY_COLOR = Color.darkred
export (Color) var TWEEN_COLOR = Color.lightcoral
export var IS_ENEMY = true 

onready var HEALTH_BAR = $HealthBar
onready var DAMAGE_BAR = $DamageBar
onready var TWEEN = $Tween

func update_hp(new_hp):
	new_hp *= 100 # scaled for smoother tweening
	if new_hp > HEALTH_BAR.max_value:
		new_hp = HEALTH_BAR.max_value
	HEALTH_BAR.value = new_hp
	_do_health_tween(new_hp)
	_update_color(new_hp)
	
func set_max(max_hp):
	HEALTH_BAR.max_value = max_hp * 100 # values scaled for smoother tweening
	DAMAGE_BAR.max_value = max_hp * 100
	_init_color()

func _do_health_tween(new_hp):
	TWEEN.stop(DAMAGE_BAR)
	TWEEN.interpolate_property(DAMAGE_BAR, "value", DAMAGE_BAR.value, new_hp, 0.4, TWEEN.TRANS_SINE, TWEEN.EASE_IN_OUT, TWEEN_DELAY)
	TWEEN.start()

func _update_color(new_hp):
	if IS_ENEMY:
		return

	if new_hp < CRITICAL_THRESH * HEALTH_BAR.max_value:
		HEALTH_BAR.tint_progress = P_CRITICAL_COLOR
	elif new_hp < HURT_THRESH * HEALTH_BAR.max_value:
		HEALTH_BAR.tint_progress = P_HURT_COLOR
	else:
		HEALTH_BAR.tint_progress = P_HEALTHY_COLOR

func _init_color():
	DAMAGE_BAR.tint_progress = TWEEN_COLOR
	if IS_ENEMY:
		HEALTH_BAR.tint_progress = ENEMY_COLOR
	else:
		HEALTH_BAR.tint_progress = P_HEALTHY_COLOR
