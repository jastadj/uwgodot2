extends KinematicBody

onready var world = get_parent()
onready var _camera_translation = $Camera.translation

var _dbg_toggle = false

func _ready():
	
	# 32,62 is level one start cell, for testing
	translation = Vector3(32,0,62) * UW.TILESIZE

func _physics_process(delta):
	
	# player on tile
	var tile_x = int(translation.x/UW.TILESIZE)
	var tile_y = int(translation.z/UW.TILESIZE)
	
	if tile_x > 0 and tile_x < world._cells_x and tile_y > 0 and tile_y < world._cells_y:
		var current_tile = world.level["cells"][tile_y][tile_x]
		
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
