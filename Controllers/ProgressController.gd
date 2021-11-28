extends Node

export var DIFFICULTY = 1 # 0 = easy, 1 = medium, 2 = hard
export var CAM_TRAN_TWEEN_TIME = 3 # time, in seconds, to transition between regular and boss cam (should match boss healthbar tween time)

onready var ROOT = get_tree().get_root().get_node("World")
onready var PLAYER = ROOT.get_node("Astronaut")
onready var SPAWNER = ROOT.get_node("Spawner")
onready var PLAYER_GUN = PLAYER.get_node("Primary Weapon")
onready var DIFFICULTY_CONTROLLER = $DifficultyController
onready var MAX_STAGE = 5 # number of ship parts on map
onready var soundPickup = $PartPickupSound
onready var stage_point = PLAYER.global_position
onready var TEXTBOX = ROOT.get_node("TextBoxOverlay")
onready var BOSS = preload("res://Enemy Objects/Boss/Boss.tscn")
onready var BOSS_CAM = ROOT.get_node("BossCamera")
onready var TWEEN = $Tween
onready var GLOBALS = ROOT.get_node("Globals")

var isBossStage = false
var stage = 0 # measures progress (number of ship parts collected)
var boss_entity

func _process(delta):
	if Input.is_action_just_pressed("dev_skip"):
		stage = 4
		advance()

func _ready():
	SPAWNER.enabled = false
	PLAYER.set_process(false)
	PLAYER.set_physics_process(false)
	PLAYER_GUN.set_process(false)
	
func start(difficulty):
	DIFFICULTY = difficulty
	DIFFICULTY_CONTROLLER.DIFFICULTY = difficulty
	SPAWNER.change_rate(DIFFICULTY_CONTROLLER.get_spawn_rate())
	_do_dialogue()
	yield(TEXTBOX, "has_become_inactive")
	_soft_unpause()

func advance():
	print("advancing stage")
	soundPickup.play()

	_clear_enemies()
	_soft_pause()
	_advance_stage()
	_reset_player()
	var choice = _do_dialogue()
	yield(TEXTBOX, "has_become_inactive")
	if stage == MAX_STAGE:
		if choice.outcome == TEXTBOX.BinaryChoice.option.LEFT:
			isBossStage = true
			TEXTBOX.queue_text(". . .")
			TEXTBOX.queue_text("What a shame")
			yield(TEXTBOX, "has_become_inactive")
			_do_boss_scene()
			yield(boss_entity, "is_ready")
			_update_cam_globals()
			_enable_spawner_for_boss_scene()
	_soft_unpause()

	SPAWNER.change_rate(DIFFICULTY_CONTROLLER.get_spawn_rate())
	if stage == MAX_STAGE:
		SPAWNER.enabled = false
		

func get_stage():
	return stage

func _advance_stage():
	stage += 1

func _reset_player():
	PLAYER.health = PLAYER.MAX_HP
	PLAYER.HEALTH_BAR.update_hp(PLAYER.MAX_HP)
	PLAYER.global_position = stage_point
	PLAYER.animationState.travel("Idle")

func _do_dialogue():
	match stage:
		0:
			return _stage_zero_dialogue()
		1:
			return _stage_one_dialogue()
		2:
			return _stage_two_dialogue()
		3:
			return _stage_three_dialogue()
		4:
			return _stage_four_dialogue()
		5:
			return _stage_five_dialogue()

func _stage_zero_dialogue():
	TEXTBOX.queue_text("This is some immediate dialogue")
	TEXTBOX.queue_text("It plays right as the game starts (after the menu)")
	TEXTBOX.queue_text("Narratively, this is right after the crash")
	TEXTBOX.queue_text("Go collect the parts to advance")

func _stage_one_dialogue():
	TEXTBOX.queue_text("Oh boy, the player just collected their first part!")
	TEXTBOX.queue_text("Aint that neat")
	
func _stage_two_dialogue():
	TEXTBOX.queue_text("Part number 2!")
	TEXTBOX.queue_text("At this point, the player might notice the game getting harder")
	TEXTBOX.queue_text("And if they haven't, they definitely will soon")
	TEXTBOX.queue_text("Maybe the other astronaut should tell the player the mobs are getting stronger")
	
func _stage_three_dialogue():
	TEXTBOX.queue_text("Part number 3!")
	TEXTBOX.queue_text("The game is pretty tough now")
	TEXTBOX.queue_text("At this point, the other astronaut is alluding to the ending twist")
	TEXTBOX.queue_text("Maybe they get a little pet alien or something, Idk")
	
func _stage_four_dialogue():
	TEXTBOX.queue_text("Only 1 more part to go!")
	TEXTBOX.queue_text("The player should probably be a little suspicious of the other astronaut now")
	
func _stage_five_dialogue():
	TEXTBOX.queue_text("Wowee, look at you completing the game")
	TEXTBOX.queue_text(". . .")
	TEXTBOX.queue_text(". . .")
	TEXTBOX.queue_text("Are you going to radio home now?")
	var choice = TEXTBOX.BinaryChoice.new().set_options("Radio home", "Do nothing")
	TEXTBOX.queue_text(choice)
	return choice

func _soft_pause():
	PLAYER.set_process(false)
	PLAYER.set_physics_process(false)
	PLAYER_GUN.set_process(false)
	SPAWNER.enabled = false
	
func _soft_unpause():
	PLAYER.set_process(true)
	PLAYER.set_physics_process(true)
	PLAYER_GUN.set_process(true)
	SPAWNER.enabled = true

func _clear_enemies():
	var root = get_tree().get_root().get_node("World")
	for child in root.get_children():
		if child is Enemy:
			child.kill()

func _do_boss_scene():
	_switch_to_boss_cam()
	boss_entity = BOSS.instance()
	var ASTRO_NPC = get_tree().get_root().get_node("World").get_node("OtherAstro")
	boss_entity.global_position = ASTRO_NPC.global_position
	ASTRO_NPC.queue_free()
	get_tree().get_root().get_node("World").add_child(boss_entity)
	boss_entity.refresh_node_references()
	boss_entity.set_process(false)
	boss_entity.set_physics_process(false)

func _switch_to_boss_cam():
	BOSS_CAM.current = true
	TWEEN.interpolate_property(BOSS_CAM, "position", BOSS_CAM.position, BOSS_CAM.position + Vector2(0,16), CAM_TRAN_TWEEN_TIME, TWEEN.TRANS_SINE, TWEEN.EASE_OUT, 0)
	TWEEN.interpolate_property(BOSS_CAM, "zoom", BOSS_CAM.zoom, BOSS_CAM.zoom + Vector2(.25,.25), CAM_TRAN_TWEEN_TIME, TWEEN.TRANS_SINE, TWEEN.EASE_OUT, 0)
	TWEEN.start()

func _enable_spawner_for_boss_scene():
	stage = 0 # use stage 0 difficulty scaling
	SPAWNER.enabled = true
	SPAWNER.change_rate(DIFFICULTY_CONTROLLER.get_spawn_rate() - 10)

func _update_cam_globals():
	GLOBALS.cam_width *= 1.25
	GLOBALS.cam_height *= 1.25
	GLOBALS.fix_cam_center(BOSS_CAM.global_position)
