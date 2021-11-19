extends CanvasLayer

const READ_RATE = 0.04 # smaller = faster

signal has_become_inactive

onready var PARENT_MARGIN = $ParentMargin
onready var START_SYMBOL = $ParentMargin/TextMargin/TextContainer/Start
onready var END_SYMBOL = $ParentMargin/TextMargin/TextContainer/End
onready var BODY = $ParentMargin/TextMargin/TextContainer/Body
onready var TWEEN = $Tween
onready var soundTextScroll = $TextScrollSound

export var FLASH_FREQ = 0.5

var is_end_sym_flashing = false
var flash_timer = FLASH_FREQ
var is_complete = true # is tween complete (or inactive)
var queue = [] # FIFO queue for text

func queue_text(text):
	PARENT_MARGIN.visible = true
	if is_complete and queue.empty():
		_change_text(text)
	else:
		queue.append(text)

func _ready():
	PARENT_MARGIN.visible = false

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		if !is_complete:
			# text is being read; input causes read completion
			_finish_tween()
		elif queue.empty():
			# text has been read (or no text at all) and queue is empty
			# textbox becomes inactive
			emit_signal("has_become_inactive")
			PARENT_MARGIN.visible = false
		else:
			# text has been read (or no text at all) but queue has text
			# change to next text in queue
			PARENT_MARGIN.visible = true
			_change_text(_dequeue())
	
	if is_end_sym_flashing:
		if flash_timer > 0:
			flash_timer -= delta 
		else:
			if END_SYMBOL.text == "v":
				END_SYMBOL.text = ""
			else:
				END_SYMBOL.text = "v"
			flash_timer = FLASH_FREQ

func _change_text(text):
	soundTextScroll.play()
	END_SYMBOL.text = ""
	BODY.text = text
	BODY.percent_visible = 0
	TWEEN.interpolate_property(BODY, "percent_visible", 0.0, 1.0, len(text) * READ_RATE, TWEEN.TRANS_LINEAR, TWEEN.EASE_IN_OUT)
	TWEEN.start()
	is_end_sym_flashing = false
	is_complete = false

func _finish_tween():
	TWEEN.stop(BODY, "percent_visible")
	BODY.percent_visible = 1
	_finished_state()

func _on_Tween_tween_completed(object, key):
	_finished_state()

func _finished_state():
	soundTextScroll.stop()
	END_SYMBOL.text = "v"
	is_end_sym_flashing = true
	flash_timer = FLASH_FREQ
	is_complete = true
		

func _dequeue():
	return queue.pop_front()
