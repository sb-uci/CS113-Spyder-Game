extends CanvasLayer

const READ_RATE = 0.04 # smaller = faster

onready var PARENT_MARGIN = $ParentMargin
onready var START_SYMBOL = $ParentMargin/TextMargin/TextContainer/Start
onready var END_SYMBOL = $ParentMargin/TextMargin/TextContainer/End
onready var BODY = $ParentMargin/TextMargin/TextContainer/Body
onready var TWEEN = $Tween

export var FLASH_FREQ = 0.5

var is_end_sym_flashing = false
var flash_timer = FLASH_FREQ
var is_complete = true # is tween complete (or inactive)
var is_waiting_input = false # is waiting for user to click to proceed to next text
var queue = [] # FIFO queue for text

func _ready():
	queue_text("This is brand new text!")
	queue_text("This is queued text")
	queue_text("This is really long queued text which consists of multiple lines")
	queue_text("This is more queued text")

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		if !is_complete:
			finish_tween()
		else:
			is_waiting_input = false
	
	if !is_waiting_input and is_complete and !queue.empty():
		change_text(_dequeue())
	
	if is_end_sym_flashing:
		if flash_timer > 0:
			flash_timer -= delta 
		else:
			if END_SYMBOL.text == "v":
				END_SYMBOL.text = ""
			else:
				END_SYMBOL.text = "v"
			flash_timer = FLASH_FREQ

func change_text(text):
	END_SYMBOL.text = ""
	BODY.text = text
	BODY.percent_visible = 0
	TWEEN.interpolate_property(BODY, "percent_visible", 0.0, 1.0, len(text) * READ_RATE, TWEEN.TRANS_LINEAR, TWEEN.EASE_IN_OUT)
	TWEEN.start()
	is_end_sym_flashing = false
	is_complete = false

func queue_text(text):
	queue.append(text)

func finish_tween():
	TWEEN.stop(BODY, "percent_visible")
	BODY.percent_visible = 1
	_finished_state()

func _on_Tween_tween_completed(object, key):
	_finished_state()

func _finished_state():
	END_SYMBOL.text = "v"
	is_end_sym_flashing = true
	flash_timer = FLASH_FREQ
	is_complete = true
	if !queue.empty():
		is_waiting_input = true

func _dequeue():
	return queue.pop_front()
