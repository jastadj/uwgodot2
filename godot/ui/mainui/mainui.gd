extends Control

onready var _main = $main

func _ready():
	
	# build UI
	_main.texture = UW.data["uw1"]["images"]["main"][0]
	
	if get_tree().current_scene == self:
		rect_scale = Vector2(4,4)
