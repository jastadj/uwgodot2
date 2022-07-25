extends Control

const TILE_SIZE = 32
const COLS = 16
const EXPORT_FILENAME = "export_pal.png"

onready var _game_type_list = $PanelContainer/VBoxContainer/game_type_list
onready var _pal_type_list = $PanelContainer/VBoxContainer/pal_type
onready var _pal = $pal
onready var _pal_index_text = $PanelContainer/VBoxContainer/pal_index

var palettes = null
var aux_palettes = null

var _current_pal = null
var _pal_index = 0
var _pal_scale = 32
var _pal_img = null
var _texture_img = null

func _ready():
	
	# add game types to game list
	for game in UW.data.keys():
		_game_type_list.add_item(game)
	
	# connect game type list
	_game_type_list.connect("item_selected", self, "_on_game_type_selected")
	_pal_type_list.connect("item_selected", self, "_on_pal_type_selected")
	
	# create white image for color info box
	var newimg = Image.new()
	newimg.create(32,32, false, Image.FORMAT_RGBA8)
	newimg.lock()
	newimg.fill(Color(1,1,1))
	newimg.unlock()
	var newtexture = ImageTexture.new()
	newtexture.create_from_image(newimg, 0)
	$pal_info/VBoxContainer/color.texture = newtexture
	$pal_info/VBoxContainer/color2.texture = newtexture
	
	$pal_info.hide()
	
	# select first game type by default
	_on_game_type_selected(0)
	
	$PanelContainer/VBoxContainer/export_button.connect("pressed", self, "_on_export_button_pressed")
	$msg.hide()

func _process(delta):
	
	if _current_pal != null and _pal.get_child_count() > 0:
		var mouse_pos = _pal.get_local_mouse_position()
		if (mouse_pos.x >= 0 and mouse_pos.x < COLS*_pal_scale) and (mouse_pos.y >= 0 and mouse_pos.y < COLS*_pal_scale):
			var index
			$pal_info.show()
			# convert mouse_pos to index
			mouse_pos.x = floor(mouse_pos.x / _pal_scale)
			mouse_pos.y = floor(mouse_pos.y / _pal_scale)
			index = (mouse_pos.y * COLS) + (int(mouse_pos.x) % COLS)
			if _current_pal == palettes:
				_update_pal_info(index, _current_pal[_pal_index][index])
			elif _current_pal == aux_palettes:
				$pal_info.hide()
			else:
				$pal_info.hide()
		else:
			$pal_info.hide()

func _input(event):
	
	if event.is_action_pressed("ui_left"):
		_pal_index -= 1
		_update_pal()
	elif event.is_action_pressed("ui_right"):
		_pal_index += 1
		_update_pal()

func _on_game_type_selected(item):
	
	# clear palette list
	_pal_type_list.clear()
	palettes = null
	aux_palettes = null
	
	# clear palette
	_clear_palette()
	
	# reset palette index
	_pal_index = 0
	
	# if item is not valid, clear pointers
	if item == null or item == -1:
		palettes = null
		aux_palettes = null
		_update_pal()
		return
	
	# get game item name
	var itemname = _game_type_list.get_item_text(item)
	
	# update pointers
	if UW.data[itemname].has("palettes"): palettes = UW.data[itemname]["palettes"]
	if UW.data[itemname].has("aux_palettes"): aux_palettes = UW.data[itemname]["aux_palettes"]
	
	# add to pal type list if they exist
	if palettes != null: _pal_type_list.add_item("Palettes")
	if aux_palettes != null: _pal_type_list.add_item("Aux Palettes")

func _on_pal_type_selected(item):
	var itemstr = _pal_type_list.get_item_text(item)
	
	_current_pal = null
	_clear_palette()
	
	if itemstr == "Palettes" and palettes != null:
		_current_pal = palettes
	elif itemstr == "Aux Palettes" and aux_palettes != null:
		_current_pal = aux_palettes
	
	_update_pal()

func _update_pal():
	_clear_palette()
	if _current_pal == null:
		_pal_index = 0
		return;
	
	# check that index is within bounds
	if _pal_index < 0: _pal_index = 0
	elif _pal_index >= _current_pal.size(): _pal_index = _current_pal.size()-1
	
	# build palette texture
	_pal_img = Image.new()
	_pal_img.create(COLS, COLS, false, Image.FORMAT_RGBA8)
	_pal_img.lock()
	for i in range(0, _current_pal[_pal_index].size()):
		var y = i / COLS
		var x = i - (y*COLS)
		var color
		if _current_pal == palettes:
			color = _current_pal[_pal_index][i]
		elif _current_pal == aux_palettes:
			color = palettes[0][ _current_pal[_pal_index][i] ]
		_pal_img.set_pixel(x, y, color)
	_pal_img.unlock()
	
	# create texture and sprite
	var newtexture = ImageTexture.new()
	newtexture.create_from_image(_pal_img, 0)
	var newsprite = Sprite.new()
	newsprite.texture = newtexture
	newsprite.centered = false
	newsprite.scale = Vector2(_pal_scale, _pal_scale)
	
	# add palette rotator shader if palette 0
	if _current_pal == palettes and _pal_index == 0:
		newsprite.material = UW.data["uw1"]["rotating_palette_shader"]
	
	_pal.add_child(newsprite)
	
	_pal_index_text.show()
	_pal_index_text.text = str("INDEX: ", _pal_index)
	
	# get the texture image (reverse process)
	_texture_img = newtexture.get_data()
	
func _clear_palette():
	# delete any existing pal data
	for c in _pal.get_children():
		_pal.remove_child(c)
		c.queue_free()
	_pal_index_text.hide()
	
	if _texture_img:
		_texture_img = null

func _update_pal_info(index, color):
	$pal_info/VBoxContainer/color.self_modulate = color
	$pal_info/VBoxContainer/red.text = str("R: ", color.r)
	$pal_info/VBoxContainer/green.text = str("G: ", color.g)
	$pal_info/VBoxContainer/blue.text = str("B: ", color.b)
	$pal_info/VBoxContainer/alpha.text = str("A: ", color.a)
	var color_bytes = PoolByteArray([color.r8, color.g8, color.b8])
	$pal_info/VBoxContainer/hex.text = str("HEX: #", color_bytes.hex_encode())
	$pal_info/VBoxContainer/color_index.text = str("COLOR INDEX: ", index)
	
	if _texture_img:
		var y = int(index / COLS)
		var x = index - (y*COLS)
		print(Vector2(x,y))
		var tpixel = _texture_img.get_pixel(x,y)
		$pal_info/VBoxContainer/color2.self_modulate = tpixel
		$pal_info/VBoxContainer/red2.text = str("R: ", tpixel.r)
		$pal_info/VBoxContainer/green2.text = str("G: ", tpixel.g)
		$pal_info/VBoxContainer/blue2.text = str("B: ", tpixel.b)
		$pal_info/VBoxContainer/alpha2.text = str("A: ", tpixel.a)
	
func _on_export_button_pressed():
	if _pal_img != null:
		if _pal_img.save_png(EXPORT_FILENAME) == 0:
			$msg.text = str("Palette exported to ", EXPORT_FILENAME)
			$msg.show()
			yield(get_tree().create_timer(2.0), "timeout")
			$msg.hide()
		
		

