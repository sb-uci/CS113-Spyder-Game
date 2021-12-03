extends Node

export var DIFFICULTY = 1 # 0 = easy, 1 = medium, 2 = hard
export var CAM_TRAN_TWEEN_TIME = 3 # time, in seconds, to transition between regular and boss cam (should match boss healthbar tween time)

onready var ROOT = get_tree().get_root().get_node("World")
onready var PLAYER = ROOT.get_node("Astronaut")
onready var SPAWNER = ROOT.get_node("Spawner")
onready var PLAYER_GUN = PLAYER.get_node("Primary Weapon")
onready var NAVIGATION = ROOT.get_node("Navigation")
onready var DIFFICULTY_CONTROLLER = $DifficultyController
onready var MAX_STAGE = 5 # number of ship parts on map
onready var soundPickup = $PartPickupSound
onready var stage_point = PLAYER.global_position
onready var BOSS = preload("res://Enemy Objects/Boss/Boss.tscn")
onready var BOSS_CAM = ROOT.get_node("BossCamera")
onready var ASTRO_NPC = ROOT.get_node("OtherAstro")
onready var TWEEN = $Tween
onready var musicBG = ROOT.get_node("BGMusic")
onready var musicBoss = ROOT.get_node("BossMusic")
onready var musicOutro = ROOT.get_node("OutroMusic")
onready var TEXTBOX = ROOT.get_node("TextBoxOverlay")
onready var BOSS_HP_BAR = ROOT.get_node("BossHealthBar")
onready var OUTRO_SCREEN = ROOT.get_node("OutroScreen").get_node("Controller")

var isBossStage = false
var stage = 0 # measures progress (number of ship parts collected)
var boss_entity

func end_game():
	_soft_pause()
	_clear_bullets_and_enemies(false)
	
	if isBossStage:
		# post-boss ending ("radio home" ending)
		musicBoss.stop()
		TEXTBOX.queue_text("Red: You really are determined to go through with this then.")
		TEXTBOX.queue_text("If you make it off this place. If they come. . .")
		TEXTBOX.queue_text("when they come. . .")
		TEXTBOX.queue_text("Don't ever forget what happened here.")
		TEXTBOX.queue_text("Don't forget that the blood of these creatures. . .")
		TEXTBOX.queue_text(". . .of this planet")
		TEXTBOX.queue_text(". . .of me")
		TEXTBOX.queue_text("It's on your hands.")
		TEXTBOX.queue_text("I fought for what was right.")
		TEXTBOX.queue_text(". . . ")
		TEXTBOX.queue_text("I hope one day you can say the same.")
		yield(TEXTBOX, "has_become_inactive")
		OUTRO_SCREEN.switch_to()
		musicOutro.play()
		TEXTBOX.change_scroll_speed(.05)
		TEXTBOX.queue_text("And so the two fought for their fates,")
		TEXTBOX.queue_text("both leaving a piece of themselves behind")
	else:
		# no boss ending ("do nothing" ending)
		musicBG.stop()
		TEXTBOX.queue_text("Red: I knew you'd understand.")
		TEXTBOX.queue_text("For once in our species' history")
		TEXTBOX.queue_text("we're doing the right thing.")
		TEXTBOX.queue_text(". . .")
		TEXTBOX.queue_text("And no one will even know.")
		TEXTBOX.queue_text("No one but us.")
		yield(TEXTBOX, "has_become_inactive")
		OUTRO_SCREEN.switch_to()
		musicOutro.play()
		TEXTBOX.change_scroll_speed(.05)
		TEXTBOX.queue_text("And so the two enjoyed their final moments,")
		TEXTBOX.queue_text("taking solace in what they felt was right.")

func game_over():
	_clear_bullets_and_enemies()
	_reset_player()
	musicBG.stop()
	musicBoss.stop()
	SPAWNER.enabled = false
	BOSS_HP_BAR.hide()
	BOSS_CAM.position -= Vector2(0,16)
	BOSS_CAM.zoom = Vector2(1,1)
	NAVIGATION.rebuild_objects()
	GLOBALS.reset_cam()
	_soft_pause()
	get_tree().get_root().get_node("World").get_node("Game Over").get_node("GameOver").activate()
	

func _process(delta):
	if Input.is_action_just_pressed("dev_skip"):
		if !isBossStage:
			stage = 4
			advance()

func _ready():
	SPAWNER.enabled = false
	PLAYER.set_process(false)
	PLAYER.set_physics_process(false)
	PLAYER_GUN.set_process(false)
	
func start(difficulty):
	GLOBALS.difficulty = difficulty
	DIFFICULTY = difficulty
	DIFFICULTY_CONTROLLER.DIFFICULTY = difficulty
	SPAWNER.change_rate(DIFFICULTY_CONTROLLER.get_spawn_rate())
	if GLOBALS.isBossReached:
		_skip_to_boss()
	else:
		_do_dialogue()
		yield(TEXTBOX, "has_become_inactive")
		_soft_unpause()

func advance():
	soundPickup.play()

	_clear_bullets_and_enemies()
	_soft_pause()
	_advance_stage()
	_reset_player()
	var choice = _do_dialogue()
	yield(TEXTBOX, "has_become_inactive")
	if stage == MAX_STAGE:
		if choice.outcome == TEXTBOX.BinaryChoice.option.LEFT:
			# player chose to radio home; boss fight ensues
			isBossStage = true
			GLOBALS.isBossReached = true
			TEXTBOX.queue_text(". . .")
			TEXTBOX.queue_text("What a shame")
			TEXTBOX.queue_text("I had hoped you would understand.")
			TEXTBOX.queue_text("Our lives are not more important than this planet.")
			TEXTBOX.queue_text("And if you can't make the right choice,")
			TEXTBOX.queue_text("I will.")
			yield(TEXTBOX, "has_become_inactive")
			_do_boss_scene()
			yield(boss_entity, "is_ready")
			_update_cam_globals()
			_edit_spawner_for_boss_scene()
			_soft_unpause()
			SPAWNER.enabled = false
		else:
			# player chose to do nothing; game ends
			end_game()
	else:
		_soft_unpause()
		SPAWNER.change_rate(DIFFICULTY_CONTROLLER.get_spawn_rate())
		if stage == MAX_STAGE:
			SPAWNER.enabled = false
		

func get_stage():
	return stage

func _advance_stage():
	stage += 1

func _reset_player():
	PLAYER.reset_to_defaults(stage_point)

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
	TEXTBOX.queue_text("Red: Mission successful: we landed!")
	TEXTBOX.queue_text(". . . just not how we were supposed to land.")
	TEXTBOX.queue_text("Suffice it to say, our transport back home is a bit more")
	TEXTBOX.queue_text("tenuous.")
	TEXTBOX.queue_text("I think we can scrap some parts to radio back home,")
	TEXTBOX.queue_text("but I saw a few pieces go flying off during the crash.")
	TEXTBOX.queue_text("How about you go see if you can find them.")
	TEXTBOX.queue_text("I'll see what we can pull from the ship.")
	TEXTBOX.queue_text("Be careful though. . . ")
	TEXTBOX.queue_text("When we were approaching the ground,")
	TEXTBOX.queue_text("I thought I saw movement.")

func _stage_one_dialogue():
	TEXTBOX.queue_text("Red: You're finally back!")
	TEXTBOX.queue_text("I don't believe it, there's extraterrestrial life here!")
	TEXTBOX.queue_text("We need to report this back to HQ stat.")
	TEXTBOX.queue_text("What...")	
	TEXTBOX.queue_text("...you...you killed some?")
	TEXTBOX.queue_text("What's wrong with you!?")
	TEXTBOX.queue_text("What happens if you run them extinct!?")
	TEXTBOX.queue_text(". . .")
	TEXTBOX.queue_text("Look, it's fine, I can see more in the distance,")
	TEXTBOX.queue_text("just get the parts like I told you to then we can leave")
	
func _stage_two_dialogue():
	TEXTBOX.queue_text("Red: This planet seems to inhabit more aliens then I thought.")
	TEXTBOX.queue_text("You didn't kill any this time, right?")
	TEXTBOX.queue_text("Self-defense!? I can't believe you killed more!")
	TEXTBOX.queue_text(". . .")
	TEXTBOX.queue_text("You're right...sorry I got carried away.")
	TEXTBOX.queue_text("I'm glad you're still alive.")
	TEXTBOX.queue_text("Be careful out there, they seem to be learning from us.")
	TEXTBOX.queue_text("It's incredible! They're biology is rapidly adapting to your threat.")
	TEXTBOX.queue_text("Your gun might be meaningless to some of them soon, haha...")
	
func _stage_three_dialogue():
	TEXTBOX.queue_text("Red: Hey...what do you think HQ is going to do with these aliens?")
	TEXTBOX.queue_text("Its just...almost feels like we're not suppose to be here.")
	TEXTBOX.queue_text("I mean these guys are probably going to be treated like animals.")
	TEXTBOX.queue_text("We're taking away their humanity, and for what? Research? Fame?")
	TEXTBOX.queue_text(". . .")
	TEXTBOX.queue_text("Forget what I said, just lost in thought while I was alone.")
	TEXTBOX.queue_text("Keep finding more parts.")
	
func _stage_four_dialogue():
	TEXTBOX.queue_text("Red: Great job! I'm almost done with the radio!")
	TEXTBOX.queue_text("What do you mean it doesn't look like a radio?")
	TEXTBOX.queue_text("What would you know, you're not an engineer.")
	TEXTBOX.queue_text("A weapon? Don't be ridiculous. We already have weapons.")
	TEXTBOX.queue_text("And I don't need any weapons anyway. I'm not like you.")
	TEXTBOX.queue_text("C'mon, I only need one more part.")
	
func _stage_five_dialogue():
	TEXTBOX.queue_text("Red: Finally! I completed the weap--I mean radio.")
	TEXTBOX.queue_text(". . .")
	TEXTBOX.queue_text("I need to be honest with you.")
	TEXTBOX.queue_text("We have a chance to do something great here,")
	TEXTBOX.queue_text("To spare this planet from the conquest of man.")
	TEXTBOX.queue_text("Who are we to take their lives and their home from them?")
	TEXTBOX.queue_text("We call them aliens, but we're the aliens here!")
	TEXTBOX.queue_text("We're the ones that don't belong!")
	TEXTBOX.queue_text("What makes them any less human then us!?")
	TEXTBOX.queue_text(". . . ")
	TEXTBOX.queue_text("There's a radio in the ship,") 
	TEXTBOX.queue_text("but first you need to make a choice.")
	TEXTBOX.queue_text("When we took this job, we knew there were risks.")
	TEXTBOX.queue_text("If we don't return or make any noise,")
	TEXTBOX.queue_text("no one is going to come for us,")
	TEXTBOX.queue_text("and this planet will be safe.")
	TEXTBOX.queue_text("But if you're persistent on telling HQ,")
	TEXTBOX.queue_text("they'll come and save you,")
	TEXTBOX.queue_text("but annihilate everything here in the process.")
	TEXTBOX.queue_text("Make your choice: our lives or theirs.")
	TEXTBOX.queue_text("What will it be?")

	var choice = TEXTBOX.BinaryChoice.new().set_options("Contact HQ", "Say nothing")
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

func _clear_bullets_and_enemies(include_boss=true):
	var root = get_tree().get_root().get_node("World")
	for child in root.get_children():
		if child.is_in_group("Bullet"):
			child.queue_free()
		elif include_boss and child.is_in_group("Boss"):
			BOSS_HP_BAR.hide()
			child.queue_free()
		elif child is Enemy and !child.is_in_group("Boss"):
			child.kill()

func _do_boss_scene():
	_switch_to_boss_cam()
	boss_entity = BOSS.instance()
	boss_entity.global_position = ASTRO_NPC.global_position
	ASTRO_NPC.deactivate()
	get_tree().get_root().get_node("World").add_child(boss_entity)
	boss_entity.refresh_node_references()
	boss_entity.set_process(false)
	boss_entity.set_physics_process(false)
	boss_entity.set_difficulty(DIFFICULTY)
	musicBG.stop()
	musicBoss.play()

func _switch_to_boss_cam():
	BOSS_CAM.current = true
	TWEEN.interpolate_property(BOSS_CAM, "position", BOSS_CAM.position, BOSS_CAM.position + Vector2(0,16), CAM_TRAN_TWEEN_TIME, TWEEN.TRANS_SINE, TWEEN.EASE_OUT, 0)
	TWEEN.interpolate_property(BOSS_CAM, "zoom", BOSS_CAM.zoom, Vector2(1.25,1.25), CAM_TRAN_TWEEN_TIME, TWEEN.TRANS_SINE, TWEEN.EASE_OUT, 0)
	TWEEN.start()

func _edit_spawner_for_boss_scene():
	stage = 0 # use stage 0 difficulty scaling
	SPAWNER.change_rate(DIFFICULTY_CONTROLLER.get_spawn_rate() - 10)
	SPAWNER.interval_max = 5
	SPAWNER.interval_min = 2
	SPAWNER.do_boss_scene()

func _update_cam_globals():
	GLOBALS.cam_width *= 1.25
	GLOBALS.cam_height *= 1.25
	GLOBALS.fix_cam_center(BOSS_CAM.global_position)

func _skip_to_boss():
	ASTRO_NPC.activate()
	isBossStage = false
	stage = 4
	_soft_unpause()
	advance()
