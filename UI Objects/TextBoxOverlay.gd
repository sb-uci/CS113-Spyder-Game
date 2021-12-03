extends CanvasLayer

const READ_DELAY = 0.03 # smaller = faster

signal has_become_inactive

onready var PARENT_MARGIN = $ParentMargin
onready var TEXT_CONTAINER = $ParentMargin/TextMargin/TextContainer
onready var CHOICE_CONTAINER = $ParentMargin/TextMargin/ChoiceContainer
onready var START_SYMBOL = $ParentMargin/TextMargin/TextContainer/Start
onready var END_SYMBOL = $ParentMargin/TextMargin/TextContainer/End
onready var BODY = $ParentMargin/TextMargin/TextContainer/Body
onready var CHOICE_LEFT = $ParentMargin/TextMargin/ChoiceContainer/Text/Left
onready var CHOICE_RIGHT = $ParentMargin/TextMargin/ChoiceContainer/Text/Right
onready var SELECTOR_LEFT = $ParentMargin/TextMargin/ChoiceContainer/Selector/SelectLeft
onready var SELECTOR_RIGHT = $ParentMargin/TextMargin/ChoiceContainer/Selector/SelectRight
onready var TWEEN = $Tween
onready var soundTextScroll = $TextScrollSound

export var FLASH_FREQ = 0.5

var is_end_sym_flashing = false
var flash_timer = FLASH_FREQ
var is_complete = true # is tween complete (or inactive)
var current_choice = null # current binary choice object
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
	if current_choice != null:
		if Input.is_action_pressed("ui_left"):
			SELECTOR_LEFT.text = "/\\"
			SELECTOR_RIGHT.text = ""
		elif Input.is_action_pressed("ui_right"):
			SELECTOR_LEFT.text = ""
			SELECTOR_RIGHT.text = "/\\"
	
	if Input.is_action_just_pressed("ui_accept"):
		var has_choice = current_choice != null
		
		if has_choice:
			current_choice.outcome_left() if SELECTOR_LEFT.text == "/\\" else current_choice.outcome_right()
			current_choice = null
		
		if !is_complete and !has_choice:
			# text is being read; input causes read completion
			_finish_tween()
		elif queue.empty():
			# text has been read (or no text at all) and queue is empty
			# textbox becomes inactive
			emit_signal("has_become_inactive")
			# this may seem redundant, but the emit_signal() implies concurrency,
			# so other processes may have queued text after the signal was emitted
			if queue.empty():
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
	if text is BinaryChoice:
		_change_to_choice(text)
		return
		
	TEXT_CONTAINER.visible = true
	CHOICE_CONTAINER.visible = false
	
	soundTextScroll.play()
	END_SYMBOL.text = ""
	BODY.text = text
	BODY.percent_visible = 0
	TWEEN.interpolate_property(BODY, "percent_visible", 0.0, 1.0, len(text) * READ_DELAY, TWEEN.TRANS_LINEAR, TWEEN.EASE_IN_OUT)
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

func _change_to_choice(choice):
	current_choice = choice
	TEXT_CONTAINER.visible = false
	CHOICE_CONTAINER.visible = true
	CHOICE_LEFT.text = choice.left()
	CHOICE_RIGHT.text = choice.right()
	SELECTOR_LEFT.text = "/\\"
	SELECTOR_RIGHT.text = ""

class BinaryChoice:
	enum option {LEFT, RIGHT}
	
	var left_option = "Yes"
	var right_option = "No"
	var outcome
	
	func left():
		return left_option
	
	func right():
		return right_option
	
	func set_options(left, right):
		left_option = left
		right_option = right
		return self
	
	func outcome_left():
		outcome = option.LEFT
	
	func outcome_right():
		outcome = option.RIGHT
