extends CanvasLayer

export var flash_time = .02

var flash = false
var flash_timer = 0

func _ready():
	$ColorRect.visible = false

func _process(delta):
	if flash_timer <= 0:
		$ColorRect.visible = false
	flash_timer -= delta
	
func flash():
	$ColorRect.visible = true
	flash_timer = flash_time
