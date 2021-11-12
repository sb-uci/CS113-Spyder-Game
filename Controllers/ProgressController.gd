extends Node

export var DIFFICULTY = 1 # 0 = easy, 1 = medium, 2 = hard

onready var SPAWNER = get_tree().get_root().get_node("World").get_node("Astronaut").get_node("Spawner")
onready var DIFFICULTY_CONTROLLER = $DifficultyController
onready var MAX_STAGE = 5 # number of ship parts on map

onready var isBeaten = false
onready var stage = 0 # measures progress (number of ship parts collected)

func _ready():
	SPAWNER.enabled = false
	
func start(difficulty):
	DIFFICULTY = difficulty
	DIFFICULTY_CONTROLLER.DIFFICULTY = difficulty
	SPAWNER.change_rate(DIFFICULTY_CONTROLLER.get_spawn_rate())
	SPAWNER.enabled = true

func advance():
	print("advancing stage")
	stage += 1
	if stage == MAX_STAGE:
		stage = MAX_STAGE - 1 # so spawner can keep functioning if need be
		SPAWNER.enabled = false
		isBeaten = true
	SPAWNER.change_rate(DIFFICULTY_CONTROLLER.get_spawn_rate())

func get_stage():
	return stage
