extends Control

onready var _main = $main

func _ready():
	
	# build UI
	_main.texture = UW.data["uw1"]["images"]["main"][0]
	
	if get_tree().current_scene == self:
		rect_scale = Vector2(UW.image_scale,UW.image_scale)

func _process(delta):
	
	# debug
	if get_tree().current_scene == self:
		print(OS.get_ticks_msec(),": ",get_global_mouse_position()/UW.image_scale)
