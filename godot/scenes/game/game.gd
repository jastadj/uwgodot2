extends Node2D

onready var world = $uilayer/ViewportContainer/Viewport/world
onready var _viewport_window = $uilayer/ViewportContainer

signal viewport_clicked

func _ready():
	
	$uilayer.scale = Vector2(UW.image_scale, UW.image_scale)
	
	#Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_custom_mouse_cursor(UW.current_data["cursors"][0],0,Vector2(UW.current_data["cursors"][0].get_size()/2))
	
	# when the viewport is clicked, tell the player
	connect("viewport_clicked", $uilayer/ViewportContainer/Viewport/world/player, "_on_world_clicked")
	
func _input(event):
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene("res://scenes/splash/splash.tscn")
	elif event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			
			# clicked on viewport window?
			var mouse_pos = get_global_mouse_position()
			# scale the rect to the same scale as ui
			var viewport_rect = convert_rect_to_uilayer_scale($uilayer/ViewportContainer.get_rect())
			if viewport_rect.has_point(mouse_pos):
				# send signal to the world that the mouse clicked on it
				# set the relative mouse position from the top-left of viewport
				# along with what button was clicked
				emit_signal("viewport_clicked", mouse_pos - viewport_rect.position, event.button_index)
			
			
			

func convert_rect_to_uilayer_scale(trect:Rect2):
	trect.position = trect.position*UW.image_scale
	trect.size = trect.size*UW.image_scale
	return trect
