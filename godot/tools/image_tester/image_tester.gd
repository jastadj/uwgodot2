extends Control

var current_images = null
var current_index = 0

var _image_list
var _image_index_text
var _image_texture

func _ready():
	
	_image_list = $PanelContainer/VBoxContainer/image_list
	_image_index_text = $PanelContainer/VBoxContainer/image_index
	_image_texture = $image_texture
	
	# create images list
	for i in UW.images.keys():
		_image_list.add_item(str(i))
	
	# connect image list
	_image_list.connect("item_selected", self, "_on_item_selected")
	
	update_image()

func _input(event):
	
	if event.is_action_pressed("ui_left"): shift_index(-1)
	elif event.is_action_pressed("ui_right"): shift_index(1)

func _on_item_selected(item):
	if item != null:
		current_images = UW.images[_image_list.get_item_text(item)]
	update_image()
	
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
			_image_texture.texture = null
		else:
			if current_index < 0: current_index = 0
			elif current_index >= current_images.size():
				current_index = current_images.size()-1
			
			_image_texture.texture = current_images[current_index]
	else:
		current_index = 0
		_image_texture.texture = null
	
	_image_index_text.text = str("INDEX:", current_index)
