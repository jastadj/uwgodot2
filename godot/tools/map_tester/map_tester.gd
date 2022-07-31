extends Control

const TILE_SIZE = 32

onready var _game_type_list = $PanelContainer/VBoxContainer/game_type_list
onready var _level_list = $PanelContainer/VBoxContainer/level_list
onready var _map = $map
# info
onready var _cell_info = $PanelContainer/VBoxContainer/info
onready var _cell_pos = $PanelContainer/VBoxContainer/info/cell_pos
onready var _cell_type = $PanelContainer/VBoxContainer/info/cell_type
onready var _cell_height = $PanelContainer/VBoxContainer/info/cell_height
onready var _cell_highlighter = $cell_highlighter
onready var _cell_textures = $PanelContainer/VBoxContainer/info/textures
onready var _cell_objects = $PanelContainer/VBoxContainer/info/objects

var current_game = null
var current_level = null

var shift_slew_multiplier = 4.0
var zoom = 1.0
var zoom_step = 0.1

var floor_slope
var floor_diag

func _ready():
	
	# add game types to list
	for game in UW.data.keys():
		_game_type_list.add_item(game)
		
	# connect list select
	_game_type_list.connect("item_selected", self, "_on_game_type_selected")
	_level_list.connect("item_selected", self, "_on_level_selected")
	
	# select first game in the list by default
	if _game_type_list.get_item_count() > 0: _on_game_type_selected(0)

	# create sprites for slope/diag
	floor_slope = Sprite.new()
	floor_slope.self_modulate = Color(0,1,0,0.28)
	floor_slope.centered = false
	floor_slope.texture = ResourceLoader.load("res://tools/map_tester/floor_slope.png")	
	floor_diag = Sprite.new()
	floor_diag.centered = false
	floor_diag.texture = ResourceLoader.load("res://tools/map_tester/floor_diag.png")
	
	#_map.scale = Vector2(0.5,0.5)

func _process(delta):
	
	# map zoom
	_map.scale = Vector2(zoom, zoom)
	_cell_highlighter.rect_scale = _map.scale
	
	if current_level:
		
		_cell_info.show()
		_cell_highlighter.show()
		
		var map_pos = _map.position
		var mouse_rel = _map.get_local_mouse_position()
		var valid_cell = false
		
		mouse_rel.x = floor(mouse_rel.x / TILE_SIZE)
		mouse_rel.y = floor(mouse_rel.y / TILE_SIZE)
		_cell_pos.text = str("CELL: ", mouse_rel)
		
		# highlight mouse-over cell
		_cell_highlighter.rect_position = map_pos + Vector2(mouse_rel.x*TILE_SIZE, mouse_rel.y*TILE_SIZE)
		_cell_highlighter.rect_position = _map.to_global(_cell_highlighter.rect_position - _map.position)
		
		valid_cell = _is_valid_cell(mouse_rel)
		_cell_highlighter.visible = valid_cell
		
		# check if highlighted cell is valid
		if valid_cell:
			var current_cell = current_level["cells"][int(mouse_rel.y)][int(mouse_rel.x)]
			_cell_info.visible = true
			_cell_highlighter.visible = true
			
			var celltypestr
			match current_cell["type"]:
				0: celltypestr = "SOLID"
				1: celltypestr = "OPEN"
				2: celltypestr = "DIAG, OPEN SE"
				3: celltypestr = "DIAG, OPEN SW"
				4: celltypestr = "DIAG, OPEN NE"
				5: celltypestr = "DIAG, OPEN NW"
				6: celltypestr = "SLOPE UP NORTH"
				7: celltypestr = "SLOPE UP SOUTH"
				8: celltypestr = "SLOPE UP EAST"
				9: celltypestr = "SLOPE UP WEST"
				
			_cell_type.text = str("TYPE: ", celltypestr)
			_cell_height.text = str("HEIGHT: ", current_cell["floor_height"])
			
			# cell floor texture
			if current_cell["type"] == 0:
				_cell_textures.get_node("floor/TextureRect").texture = null
				_cell_textures.get_node("wall/TextureRect").texture = null
			else:
				_cell_textures.get_node("floor/TextureRect").texture = current_game["images"]["floors"][ current_cell["floor_texture"]]
				_cell_textures.get_node("wall/TextureRect").texture = current_game["images"]["walls"][ current_cell["wall_texture"]]
			
			# object list
			_cell_objects.clear()
			var current_obj = null
			if current_cell["object_index"] != 0: current_obj = current_level["objects"][current_cell["object_index"]]
			while current_obj != null:
				_cell_objects.add_item(str(current_obj["id"]))
				if current_obj["next"] == 0: current_obj = null
				else: current_obj = current_level["objects"][current_obj["next"]]
				
			
			# cell wall texture
		else:
			_cell_info.visible = false
			
		
	else:
		_cell_info.hide()
		_cell_highlighter.hide()
		

func _input(event):
	
	var smod = 2.0
	if Input.is_key_pressed(KEY_SHIFT): smod = shift_slew_multiplier
		
	
	if event.is_action_pressed("ui_up"): _shift_map(0, TILE_SIZE*smod)
	elif event.is_action_pressed("ui_down"): _shift_map(0, -TILE_SIZE*smod)
	elif event.is_action_pressed("ui_left"): _shift_map(TILE_SIZE*smod, 0)
	elif event.is_action_pressed("ui_right"): _shift_map(-TILE_SIZE*smod, 0)
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			zoom += zoom_step
		elif event.button_index == BUTTON_WHEEL_DOWN:
			zoom -= zoom_step
	

func _on_game_type_selected(item):
	
	var game_string
	
	# if not a valid game type, clear everything
	if item == null or item == -1:
		current_game = null
		_update_level_list()
		return
	
	game_string = _game_type_list.get_item_text(item)
	current_game = UW.data[game_string]
	
	# clear data
	_clear_level_node()
	
	# update level list
	_update_level_list()

func _on_level_selected(item):
	
	current_level = current_game["map"]["levels"][item]
	_update_level_node()

func _update_level_list():
	
	_level_list.clear()
	
	if current_game == null:
		_update_level_node()
		return
	
	# list out levels
	for i in range(0, current_game["map"]["levels"].size()):
		_level_list.add_item(str(i))
	

func _clear_level_node():
	for child in _map.get_children():
		_map.remove_child(child)
		child.queue_free()

func _update_level_node():
	
	# clear the level node
	_clear_level_node()
	
	# if no valid current game then theres no valid current level
	if current_game == null:
		current_level = null
		
	# no valid current level
	if current_level == null:
		return
	
	# add floor textures (32x32 textures)
	for y in range(0, current_level["cells"].size()):
		for x in range(0, current_level["cells"][y].size()):
			var current_cell = current_level["cells"][y][x]
			var type = current_cell["type"]
			
			# if type is not a solid wall, draw a sprite in that cell
			if type != 0:
				var newsprite = Sprite.new()
				newsprite.texture = current_game["images"]["floors"][ current_cell["floor_texture"]]
				newsprite.position = Vector2(TILE_SIZE*x, TILE_SIZE*y)
				newsprite.centered = false
				
				# if cell is a diagonal, add the diagonal sprite onto it
				if type >= 2 and type <= 5:
					var diagsprite = floor_diag.duplicate()
					newsprite.add_child(diagsprite)
					
					# rotate sprite as needed
					if type == 2: pass
					elif type == 3: diagsprite.flip_h = true
					elif type == 4: diagsprite.flip_v = true
					elif type == 5:
						diagsprite.flip_v = true
						diagsprite.flip_h = true
				# if cell is a slope, add the slope shading to it
				elif type >= 6 and type <= 9:
					var slopesprite = floor_slope.duplicate()
					newsprite.add_child(slopesprite)
					
					# rotate sprite as needed
					if type == 6: pass
					elif type == 7:
						slopesprite.flip_v = true
					elif type == 8:
						slopesprite.rotation_degrees = 90
						slopesprite.position.x += TILE_SIZE
					elif type == 9:
						slopesprite.rotation_degrees = -90
						slopesprite.position.y += TILE_SIZE
					
				
				_map.add_child(newsprite)

func _is_valid_cell(pos:Vector2):
	if current_level == null: return false
	
	var x = int(pos.x)
	var y = int(pos.y)
	
	if y < 0 or y >= current_level["cells"].size(): return false
	if x < 0 or x >= current_level["cells"][y].size(): return false
	
	return true

func _shift_map(xamount, yamount):
	_map.position += Vector2(xamount,yamount)
