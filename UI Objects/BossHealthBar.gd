extends CanvasLayer

export var TWEEN_DELAY = 0.1
export (Color) var HEALTH_COLOR = Color.darkred
export (Color) var TWEEN_COLOR = Color.lightcoral

onready var HEALTH_BAR = $HealthBars/HealthBar
onready var TWEEN_BAR = $HealthBars/TweenBar
onready var TWEEN = $Tween

const left_cutoff = .16 # percent of max value where progress bar is no longer visible
const right_cutoff = .95 # percent of max value where progress bar no longer grows

var scale_factor = 1 / (1 - ((1 - right_cutoff) + left_cutoff))
var true_max
var true_min

func show():
	$HealthBars.visible = true

func _ready():
	HEALTH_BAR.tint_progress = HEALTH_COLOR
	TWEEN_BAR.tint_progress = TWEEN_COLOR

func update_hp(new_hp):
	new_hp += true_min
	if new_hp >= true_max * right_cutoff:
		new_hp = true_max * right_cutoff
	new_hp *= 100 # scaled for smoother tweening
	HEALTH_BAR.value = new_hp
	_do_health_tween(new_hp)
	
func set_max(max_hp):
	# increases max hp to the equivalent hp without cutoffs
	true_max = max_hp * scale_factor
	true_min = true_max * left_cutoff
	
	HEALTH_BAR.value = true_min * 100
	TWEEN_BAR.value = true_min * 100
	HEALTH_BAR.max_value = true_max * 100 # values scaled for smoother tweening
	TWEEN_BAR.max_value = true_max * 100
	
	TWEEN.interpolate_property(HEALTH_BAR, "value", HEALTH_BAR.value, HEALTH_BAR.max_value, 3, TWEEN.TRANS_SINE, TWEEN.EASE_IN_OUT, 0)
	TWEEN.interpolate_property(TWEEN_BAR, "value", TWEEN_BAR.value, TWEEN_BAR.max_value, 3, TWEEN.TRANS_SINE, TWEEN.EASE_OUT, 0)
	TWEEN.start()

func _do_health_tween(new_hp):
	TWEEN.stop(TWEEN_BAR)
	TWEEN.interpolate_property(TWEEN_BAR, "value", TWEEN_BAR.value, new_hp, 0.4, TWEEN.TRANS_SINE, TWEEN.EASE_IN_OUT, TWEEN_DELAY)
	TWEEN.start()
