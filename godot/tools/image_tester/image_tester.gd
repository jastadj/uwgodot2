extends Control

var current_images = null
var current_index = 0

var _game_type_list
var _game_current = null
var _image_list
var _image_index_text
var _image_texture

var zoom = 4.0
var zoom_step = 0.1

func _ready():
	
	_image_list = $PanelContainer/VBoxContainer/image_list
	_image_index_text = $PanelContainer/VBoxContainer/image_index
	_image_texture = $image_texture
	
	_game_type_list = $PanelContainer/VBoxContainer/game_type_list
	
	# add game types to game list
	for game in UW.data.keys():
		_game_type_list.add_item(game)
	
	# connect game type list
	_game_type_list.connect("item_selected", self, "_on_game_type_selected")
	
	# connect image list
	_image_list.connect("item_selected", self, "_on_item_selected")
	
	if _game_type_list.get_item_count(): _on_game_type_selected(0)
	
	# apply shader to image texture
	$image_texture.material = UW.data["uw1"]["rotating_palette_shader"]
	
	update_image()

func _process(delta):
	
	_image_texture.rect_scale = Vector2(zoom, zoom)

func _input(event):
	
	if event.is_action_pressed("ui_left"): shift_index(-1)
	elif event.is_action_pressed("ui_right"): shift_index(1)
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP: zoom += zoom_step
		elif event.button_index == BUTTON_WHEEL_DOWN: zoom -= zoom_step

func _on_item_selected(item):
	
	# reset index every time an item is selected
	current_index = 0
	
	# if the item is valid, select the image sub container
	if item != null:
		current_images = _game_current["images"][_image_list.get_item_text(item)]
	
	# update the dispalyed image
	update_image()
	
func _on_game_type_selected(item):
	
	# reset image index when changing game types
	current_index = 0
	
	# if item is valid, get the name of the item and make it current object
	var item_string
	if item == null or item == -1: return
	item_string = _game_type_list.get_item_text(item)
	print("Selecting game type:", item_string)
	_game_current = UW.data[item_string]
	
	_update_image_list()
	
func _update_image_list():
	
	_image_list.clear()
	
	# no valid game selected
	if _game_current == null:
		clear_texture()
		return
	
	if _game_current.empty():
		clear_texture()
		return
	
	# game selected, get images containers
	for i in _game_current["images"].keys():
		_image_list.add_item(i)
	
	# sort alphabetically
	_image_list.sort_items_by_text()
	
func shift_index(dir):
		var shift_mod = 1
		dir = int(clamp(dir, -1, 1))
		if Input.is_key_pressed(KEY_SHIFT): shift_mod = 10
		current_index += dir*shift_mod
		update_image()

func update_image():
	# set image texture to an index in the current images pointer
	if current_images != null:
		if current_images.empty():
			current_index = 0
			clear_texture()
		else:
			if current_index < 0: current_index = 0
			elif current_index >= current_images.size():
				current_index = current_images.size()-1
			
			_image_texture.texture = current_images[current_index]
	else:
		current_index = 0
		clear_texture()
	
	_image_index_text.text = str("INDEX:", current_index)

func clear_texture():
	_image_texture.texture = null
