extends KinematicBody

onready var world = get_parent()
onready var _camera_translation = $Camera.translation

var move_speed = 5
var collision_size = 0.2# the size of the player bounding box / 2
var _dbg_toggle = false

func _ready():
	
	# this will have to change if loading a save game
	$Camera.translation.y = UW.player["height"]
	$Camera.rotation_degrees = Vector3()
	
	# 32,62 is level one start cell, for testing
	translation = Vector3(32,0,62) * UW.TILESIZE

func _process(delta):
	pass

func _physics_process(delta):
	
	
	_handle_input(delta)
	


func _handle_input(delta):
	
	var prev_pos = translation
	var new_pos = translation
	var move_input = Vector2()
	var move_vector = Vector2()
	var move_angle = get_angle(false)
	
	
	# player on tile / player destination tile
	var tile_x = int(translation.x/UW.TILESIZE)
	var tile_y = int(translation.z/UW.TILESIZE)
	var current_cell = world.get_cell(Vector2(tile_x, tile_y))
	var current_cell_type = null
	var colliding_with_level = false
	
	# movement input
	if Input.is_action_pressed("ui_up"): move_input.y += 1
	if Input.is_action_pressed("ui_down"): move_input.y += -1
	#if Input.is_action_pressed("ui_left"): move_input.x -= 1
	#if Input.is_action_pressed("ui_right"): move_input.x += 1
	
	if current_cell: current_cell_type = current_cell["type"]
	
	# set player height on tile
	if tile_x > 0 and tile_x < world._cells_x and tile_y > 0 and tile_y < world._cells_y:
		if current_cell_type:
			var floor_height = current_cell["floor_height"]
			# adjust height depending on tile type
			# i.e sloping tiles adjust tile height on a slope
			match current_cell_type:
				# sloping to the north
				06: new_pos.y = (floor_height + 1 - ((new_pos.z/2) - int(new_pos.z/2)) ) * 0.25 * UW.TILESIZE
				# sloping to the south
				07: new_pos.y = (floor_height + ((new_pos.z/2) - int(new_pos.z/2)) ) * 0.25 * UW.TILESIZE
				# sloping to the east
				08: new_pos.y = (floor_height + ((new_pos.x/2) - int(new_pos.x/2)) ) * 0.25 * UW.TILESIZE
				# sloping to the west
				09: new_pos.y = (floor_height + 1 - ((new_pos.x/2) - int(new_pos.x/2)) ) * 0.25 * UW.TILESIZE
				# otherwise, flat ground
				_: new_pos.y = floor_height * 0.25 * UW.TILESIZE
	
	translation = new_pos
	
	
	# move player in input direction (forward/back, strafe left/right)
	move_vector = Vector2(-sin(move_angle), -cos(move_angle)) * move_input.y
	move_vector = move_vector * (move_input.length() * move_speed * delta)
	new_pos = new_pos + Vector3(move_vector.x, 0, move_vector.y)
	
	move_and_slide(Vector3(move_vector.x, 0, move_vector.y)*70, Vector3(0,1,0))
	#translation = world.collision.resolve_world_collisions(prev_pos, new_pos, move_vector, player_bb)
	
func _input(event):
	
	if event is InputEventKey:
		if event.scancode == KEY_F1:
			_dbg_toggle = !_dbg_toggle
			$Camera.fly_mode = _dbg_toggle
			$Camera.allow_move_input = _dbg_toggle
			$Camera.mouse_look = _dbg_toggle
			if !_dbg_toggle:
				$Camera.translation = _camera_translation
				$Camera.rotation_degrees = Vector3()
			print("debug mode = ", _dbg_toggle)

func get_angle(degrees:bool):
	return $Camera.rotation.y
