extends Spatial

const TILESIZE = 2 # size of tile height/width in 3d units

onready var _cells = $cells

var _cells_y = 0
var _cells_x = 0

# level meshes
var floor_meshes = [
				null,
				preload("res://scenes/world/cell_shapes/floor.tscn"),
				preload("res://scenes/world/cell_shapes/floor_diag_se.tscn"),
				preload("res://scenes/world/cell_shapes/floor_diag_sw.tscn"),
				preload("res://scenes/world/cell_shapes/floor_diag_ne.tscn"),
				preload("res://scenes/world/cell_shapes/floor_diag_nw.tscn"),
				preload("res://scenes/world/cell_shapes/floor_slope_n.tscn"),
				preload("res://scenes/world/cell_shapes/floor_slope_s.tscn"),
				preload("res://scenes/world/cell_shapes/floor_slope_e.tscn"),
				preload("res://scenes/world/cell_shapes/floor_slope_w.tscn")
				]
var wallmesh = preload("res://scenes/world/cell_shapes/wall.tscn")
var walldiagmesh = preload("res://scenes/world/cell_shapes/wall_diag.tscn")

func _ready():
	
	build_world_level(UW.data["uw1"], 0)

func get_adjacent_cells(cell, level):
	
	var x = cell["position"].x
	var y = cell["position"].y
	
	# adjacent cells
	var north = null
	var south = null
	var east = null
	var west = null
	
	# set adjacent cells
	if y != 0:
		north = level["cells"][y-1][x]
		if north["type"] == 0: north = null
	if y < _cells_y-1:
		south = level["cells"][y+1][x]
		if south["type"] == 0: south = null
	if x != 0:
		west = level["cells"][y][x-1]
		if west["type"] == 0: west = null
	if x < _cells_x-1:
		east = level["cells"][y][x+1]
		if east["type"] == 0: east = null
	
	return {UW.DIRECTION.NORTH:north,
			UW.DIRECTION.SOUTH:south,
			UW.DIRECTION.EAST:east,
			UW.DIRECTION.WEST:west}

func build_world_level(uwdata, levelnum):
	
	var floormeshes
	var map = uwdata["map"]
	var level = map["levels"][levelnum]
	_cells_y = level["cells"].size()
	_cells_x = level["cells"][0].size()
	
	# clear everything in the cells node
	for c in _cells.get_children():
		_cells.remove_child(c)
		c.queue_free()
	
	# build floor map from level data cells
	for y in range(0, _cells_y):
		for x in range(0, _cells_x):
			
			# generate cell from data
			var cell_node = build_cell(level, Vector2(x,y))
			if cell_node == null: continue
			
			# done, add node to cells
			_cells.add_child(cell_node)

func build_cell(level, pos):
	
	var cell = level["cells"][pos.y][pos.x]
	var type = cell["type"]
	var x = pos.x
	var y = pos.y
	# if solid cell, do nothing
	if type == 0: return null
	
	# create node to store cell components
	var cell_node = Spatial.new()
	cell_node.name = str("cell_",x,"_",y)
	
	# move cell into position
	cell_node.translation.x = x*TILESIZE
	cell_node.translation.z = y*TILESIZE

	# build floor
	cell_node.add_child(build_cell_floor(cell))
	
	# build walls
	cell_node.add_child(build_cell_walls(cell, get_adjacent_cells(cell, level)))

	return cell_node
	
func build_cell_floor(cell):
	var floor_node = Spatial.new()
	var type = cell["type"]
	var texture = UW.current_data["images"]["floors"][ cell["floor_texture"] ]
	# floor mesh / material
	var floormesh = floor_meshes[type].instance()
	var meshinstance = floormesh.get_node("MeshInstance")
	var material = UW.current_data["rotating_palette_spatial"].duplicate()
	material.set_shader_param("img", texture)
	meshinstance.set_surface_material(0, material)
	# adjust floor height
	meshinstance.translation.y = cell["floor_height"] * TILESIZE * 0.25
	floor_node.name = "floor"
	floor_node.add_child(floormesh)
	return floor_node

func build_cell_walls(cell, adjacent):
	
	var walls_node = Spatial.new()
	walls_node.name = "walls"
	
	var type = cell["type"]
	
	# if cell type is a diagonal wall
	if type >= 2 and type <= 5:
		walls_node.add_child(new_wall_diagonal(cell))
	else:
		for d in adjacent.keys():
			var wall = new_wall(cell, d, adjacent[d])
	
func new_wall_diagonal(cell):
	var floor_height = cell["floor_height"]
	var wall_height = 16 - floor_height
	var type = cell["type"]
	# create mes h/material
	var newwallmesh = walldiagmesh.instance()
	var meshinstance = newwallmesh.get_node("MeshInstance")
	var material = UW.current_data["rotating_palette_spatial"].duplicate()
	meshinstance.scale.y = wall_height
	material.set_shader_param("img", UW.current_data["images"]["walls"][ cell["wall_texture"] ])
	material.set_shader_param("scale", Vector2(1.0, 0.25*wall_height))
	meshinstance.set_surface_material(0, material)
	# position/rotate mesh
	meshinstance.translation.y = floor_height * TILESIZE * 0.25
	if type == 3: meshinstance.rotation_degrees.y = -90
	elif type == 4: meshinstance.rotation_degrees.y = 90
	elif type == 5: meshinstance.rotation_degrees.y = 180
	
	return meshinstance


func new_wall(cell, direction, adjacent):
	
	var wallheight = 0

	# a wall isn't built if adjacent wall is:
	# - open and same or < floor height
	# - diagonal and same < floor height and facing open in direction
	# - slope edge meets floor height
	
	# build matrix determines what/how walls are built
	# in a direction against an adjacent cell type
	# row = direction/2 (ortho direction only)
	# col = type (0-9)
	# 0 = full wall
	# 1 = wall floor delta
	# 3 = wall floor delta + 1 wall height
	# 5 = wall floor delta + slope wall
	var buildmatrix = [
						[0,1,1,1,0,0,1,3,5,5],
						[0,1,0,1,0,1,5,5,1,3],
						[0,1,0,0,1,1,3,1,5,5],
						[0,1,1,0,1,0,5,5,3,1]
						]
	# determine build flags
	var build_flags = 0
	if adjacent != null: buildmatrix[direction/2][adjacent["type"]]
	
	
	# calculate wall height
	if build_flags == 0: wallheight = 16 - cell["floor_height"]
	
		
	
	# north wall
	if (north == null or north["floor_height"] > height ) and !(type == 2 or type ==3):
		var wallheight
		if north == null: wallheight = 16-height
		else: wallheight = north["floor_height"]-height
		var newwall = new_wall(UW.data["uw1"]["images"]["walls"][cell["wall_texture"]], wallheight)
		newwall.translation.z = -1
		newwall.translation.y = newfloor.translation.y
		cell_node.add_child(newwall)
	# south wall
	if (south == null or south["floor_height"] > height) and !(type == 4 or type == 5):
		var wallheight
		if south == null: wallheight = 16-height
		else: wallheight = south["floor_height"]-height
		var newwall = new_wall(UW.data["uw1"]["images"]["walls"][cell["wall_texture"]], wallheight)
		newwall.translation.z = 1
		newwall.rotation_degrees.y = 180
		newwall.translation.y = newfloor.translation.y
		cell_node.add_child(newwall)
	# west wall
	if (west == null or west["floor_height"] > height) and !(type == 2 or type == 4):
		var wallheight
		if west == null: wallheight = 16-height
		else: wallheight = west["floor_height"]-height
		var newwall = new_wall(UW.data["uw1"]["images"]["walls"][cell["wall_texture"]], wallheight)
		newwall.translation.x = -1
		newwall.rotation_degrees.y = 90
		newwall.translation.y = newfloor.translation.y
		cell_node.add_child(newwall)
	# east wall
	if (east == null or east["floor_height"] > height) and !(type == 3 or type == 5):
		var wallheight
		if east == null: wallheight = 16-height
		else: wallheight = east["floor_height"]-height
		var newwall = new_wall(UW.data["uw1"]["images"]["walls"][cell["wall_texture"]], wallheight)
		newwall.translation.x = 1
		newwall.rotation_degrees.y = -90
		newwall.translation.y = newfloor.translation.y
		cell_node.add_child(newwall)
	
	
	var newwallmesh = wallmesh.instance()
	var meshinstance = newwallmesh.get_node("MeshInstance")
	var material = UW.data["uw1"]["rotating_palette_spatial"].duplicate()
	meshinstance.scale.y = height
	material.set_shader_param("img", texture)
	material.set_shader_param("scale", Vector2(1.0, 0.25*height))
	meshinstance.set_surface_material(0, material)
	
	return newwallmesh
	

