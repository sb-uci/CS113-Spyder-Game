extends Node

export var DIFFICULTY = 1 # 0 = easy, 1 = medium, 2 = hard

onready var PLAYER = get_tree().get_root().get_node("World").get_node("Astronaut")
onready var SPAWNER = PLAYER.get_node("Spawner")
onready var PLAYER_GUN = PLAYER.get_node("Primary Weapon")
onready var DIFFICULTY_CONTROLLER = $DifficultyController
onready var MAX_STAGE = 5 # number of ship parts on map
onready var soundPickup = $PartPickupSound

onready var isBeaten = false
onready var stage = 0 # measures progress (number of ship parts collected)

func _ready():
	SPAWNER.enabled = false
	PLAYER.set_process(false)
	PLAYER.set_physics_process(false)
	PLAYER_GUN.set_process(false)
	
func start(difficulty):
	PLAYER.set_process(true)
	PLAYER.set_physics_process(true)
	PLAYER_GUN.set_process(true)
	DIFFICULTY = difficulty
	DIFFICULTY_CONTROLLER.DIFFICULTY = difficulty
	SPAWNER.change_rate(DIFFICULTY_CONTROLLER.get_spawn_rate())
	SPAWNER.enabled = true

func advance():
	print("advancing stage")
	soundPickup.play()
	stage += 1
	if stage == MAX_STAGE:
		stage = MAX_STAGE - 1 # so spawner can keep functioning if need be
		SPAWNER.enabled = false
		isBeaten = true
	SPAWNER.change_rate(DIFFICULTY_CONTROLLER.get_spawn_rate())

func get_stage():
	return stage
