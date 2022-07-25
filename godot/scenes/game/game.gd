extends Node2D

var viewscale = 4

onready var world = $uilayer/ViewportContainer/Viewport/world

func _ready():
	
	$uilayer.scale = Vector2(viewscale, viewscale)
	
	
func _input(event):
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://scenes/splash/splash.tscn")
