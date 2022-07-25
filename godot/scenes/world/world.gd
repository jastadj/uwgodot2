extends Spatial

onready var _cells = $cells

var _cells_y = 0
var _cells_x = 0

func _ready():
	
	build_world_level(UW.data["uw1"], 0)

func build_world_level(uwdata, levelnum):
	
	var floormeshes
	var tilesize = 2
	var map = uwdata["map"]
	var level = map["levels"][levelnum]
	_cells_y = level["cells"].size()
	_cells_x = level["cells"][0].size()
	
	# cell types
	#00      Solid (wall tile)
	#01      Open (square tile of empty space)
	#02      Diagonal, open SE
	#03      Diagonal, open SW
	#04      Diagonal, open NE
	#05      Diagonal, open NW
	#06      Sloping up to the north
	#07      Sloping up to the south
	#08      Sloping up to the east
	#09      Sloping up to the west
	floormeshes = [
				null,
				preload("res://scenes/world/cell_shapes/floor.tscn").instance(),
				preload("res://scenes/world/cell_shapes/floor_diag_se.tscn").instance(),
				preload("res://scenes/world/cell_shapes/floor_diag_sw.tscn").instance(),
				preload("res://scenes/world/cell_shapes/floor_diag_ne.tscn").instance(),
				preload("res://scenes/world/cell_shapes/floor_diag_nw.tscn").instance(),
				preload("res://scenes/world/cell_shapes/floor_slope_n.tscn").instance(),
				preload("res://scenes/world/cell_shapes/floor_slope_s.tscn").instance(),
				preload("res://scenes/world/cell_shapes/floor_slope_e.tscn").instance(),
				preload("res://scenes/world/cell_shapes/floor_slope_w.tscn").instance()
				]
	
	# clear everything in the cells node
	for c in _cells.get_children():
		_cells.remove_child(c)
		c.queue_free()
	
	# build floor map from level data cells
	for y in range(0, _cells_y):
		for x in range(0, _cells_x):
			
			var cell = level["cells"][y][x]
			var type = cell["type"]
			var height = cell["floor_height"]
			
			# if solid cell, do nothing
			if type == 0: continue
			
			# copy mesh from floor mesh types and set
			# the material and texture, then add to scene cells
			var newmesh = floormeshes[type].duplicate()
			var meshinstance = newmesh.get_node("MeshInstance")
			var floor_material = UW.data["uw1"]["rotating_palette_spatial"].duplicate()
			newmesh.translation.x = x*tilesize
			newmesh.translation.z = y*tilesize
			newmesh.translation.y = height * tilesize * 0.25
			floor_material.set_shader_param("img", UW.data["uw1"]["images"]["floors"][cell["floor_texture"]])
			meshinstance.set_surface_material(0, floor_material)
			_cells.add_child(newmesh)
			
			
