extends Node

var cam_width_default = 320
var cam_height_default = 180

var cam_width = 320
var cam_height = 180
var cam_center = Vector2(0,0)
var isCamCenterFixed = false
var reparent_counter = 1
var isBossReached = false
var difficulty = 0

func set_cam_center(center):
	if !isCamCenterFixed:
		cam_center = center

func fix_cam_center(center):
	if !isCamCenterFixed:
		cam_center = center
		isCamCenterFixed = true

func reset_cam():
	cam_width = cam_width_default
	cam_height = cam_height_default
	isCamCenterFixed = false
