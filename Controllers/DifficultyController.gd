extends Node

onready var ProgressController = get_parent()
onready var DIFFICULTY = ProgressController.DIFFICULTY # 0 = easy, 1 = medium, 2 = hard

# Guide to variable names in this class:
# e = "easy"; values for easy difficulty, formatted as [e1,e2,e3,e4,e5] for each
#		progress stage (each collected ship part)
# m = "medium"; values for medium difficulty; formatted identical to easy
# h = "hard"; values for hard difficulty; formatted identical to easy

# Scale vs Factor
# scale is additive (added to base value) (exception: SpawnScale replaces value)
# factor is multiplicative (multipled by base value)

# Enemy Health
export var eGeneralHPScale = [-1,-1,-1,0,0]
export var eBruteHPScale = [-2,-1,-1,0,0]
export var mGeneralHPScale = [0,0,0,0,1]
export var mBruteHPScale = [0,0,1,1,2]
export var hGeneralHPScale = [0,0,1,1,2]
export var hBruteHPScale = [0,1,2,3,4,5]

# Enemy Speed
export var eSpeedFactor = [0.9,0.9,1,1,1]
export var mSpeedFactor = [1,1,1,1.1,1.1]
export var hSpeedFactor = [1,1.1,1.1,1.2,1.2]

# Enemy Damage
export var eDamageFactor = [0.5,0.5,1,1,1]
export var mDamageFactor = [1,1,1,1,1.5]
export var hDamageFactor = [1,1,1.5,1.5,2]

# Enemy Shot Leading
export var eLeadScale = [0,0,0,1,1]
export var mLeadScale = [0,0,1,1,2]
export var hLeadScale = [1,1,2,8,16] # leading has diminishing returns

# Enemy Shot Speed
export var eShotSpeedFactor = [0.8,0.8,0.9,0.9,1]
export var mShotSpeedFactor = [1,1,1,1,1]
export var hShotSpeedFactor = [1,1,1.1,1.1,1.2]

# Enemy Movement Tracking (basically makes the AI smarter about its movement)
export var eTrackScale = [0,0,0,0,1]
export var mTrackScale = [0,0,1,1,2]
export var hTrackScale = [1,1,2,4,8] # tracking has diminishing returns

# Spawn Rate (avg spawns per minute)
export var eSpawnScale = [20,20,25,25,30]
export var mSpawnScale = [30,30,35,35,40]
export var hSpawnScale = [35,35,40,40,45]

var GeneralHPScale
var BruteHPScale
var SpeedFactor
var DamageFactor
var LeadScale
var ShotSpeedFactor
var TrackScale
var SpawnScale

func scale_enemy_stats(enemy):
	var stage = ProgressController.get_stage()
	if stage == ProgressController.MAX_STAGE: # prevents index out of bounds if spawner used during last stage
		stage -= 1
	if enemy.TYPE == "brute":
		enemy.MAX_HP += BruteHPScale[DIFFICULTY][stage]
	else:
		enemy.MAX_HP += GeneralHPScale[DIFFICULTY][stage]
	
	if enemy.TYPE == "shooter" or enemy.TYPE == "flyer":
		enemy.BULLET_SPEED *= ShotSpeedFactor[DIFFICULTY][stage]
		enemy.SHOT_TRACKING += LeadScale[DIFFICULTY][stage]
	
	enemy.SPEED *= SpeedFactor[DIFFICULTY][stage]
	enemy.DAMAGE *= DamageFactor[DIFFICULTY][stage]
	enemy.MOVEMENT_TRACKING += TrackScale[DIFFICULTY][stage]
	
	return enemy

func get_spawn_rate():
	var stage = ProgressController.get_stage()
	if stage == ProgressController.MAX_STAGE: # prevents index out of bounds if spawner used during last stage
		stage -= 1
	return SpawnScale[DIFFICULTY][stage]
	
func _ready():
	GeneralHPScale = [eGeneralHPScale, mGeneralHPScale, hGeneralHPScale]
	BruteHPScale = [eBruteHPScale, mBruteHPScale, hBruteHPScale]
	SpeedFactor = [eSpeedFactor, mSpeedFactor, hSpeedFactor]
	DamageFactor = [eDamageFactor, mDamageFactor, hDamageFactor]
	LeadScale = [eLeadScale, mLeadScale, hLeadScale]
	ShotSpeedFactor = [eShotSpeedFactor, mShotSpeedFactor, hShotSpeedFactor]
	TrackScale = [eTrackScale, mTrackScale, hTrackScale]
	SpawnScale = [eSpawnScale, mSpawnScale, hSpawnScale]
