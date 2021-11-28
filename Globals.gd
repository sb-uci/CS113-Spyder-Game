extends Node

var cam_width = 320
var cam_height = 180
var cam_center = Vector2(0,0)
var isCamCenterFixed = false

func set_cam_center(center):
	if !isCamCenterFixed:
		cam_center = center

func fix_cam_center(center):
	if !isCamCenterFixed:
		cam_center = center
		isCamCenterFixed = true
