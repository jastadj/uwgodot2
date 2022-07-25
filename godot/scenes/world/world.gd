extends Spatial

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

	
	# clear everything in the cells node
	for c in _cells.get_children():
		_cells.remove_child(c)
		c.queue_free()
	
	# build floor map from level data cells
	for y in range(0, _cells_y):
		for x in range(0, _cells_x):
			
			var cell = level["cells"][y][x]
			var type = cell["type"]
			
			# if solid cell, do nothing
			if type == 0: continue
			
			var cell_node = Spatial.new()
			cell_node.name = str("cell_",x,"_",y)
			cell_node.translation.x = x*tilesize
			cell_node.translation.z = y*tilesize
			
			# height
			var height = cell["floor_height"]
			
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
			
			# copy mesh from floor mesh types and set
			# the material and texture, then add to scene cells
			var newfloor = new_floor(UW.data["uw1"]["images"]["floors"][cell["floor_texture"]], type)
			newfloor.translation.y = height * tilesize * 0.25
			cell_node.add_child(newfloor)
			
			# create walls			
			# north wall
			if (north == null or north["floor_height"] > height or (north["type"] == 4 or north["type"] == 5)) and !(type == 2 or type ==3):
				var wallheight
				if north == null: wallheight = 16-height
				else: wallheight = north["floor_height"]-height
				var newwall = new_wall(UW.data["uw1"]["images"]["walls"][cell["wall_texture"]], wallheight)
				newwall.translation.z = -1
				newwall.translation.y = newfloor.translation.y
				cell_node.add_child(newwall)
			# south wall
			if (south == null or south["floor_height"] > height or (north["type"] == 4 or north["type"] == 5)) and !(type == 4 or type == 5):
				var wallheight
				if south == null: wallheight = 16-height
				else: wallheight = south["floor_height"]-height
				var newwall = new_wall(UW.data["uw1"]["images"]["walls"][cell["wall_texture"]], wallheight)
				newwall.translation.z = 1
				newwall.rotation_degrees.y = 180
				newwall.translation.y = newfloor.translation.y
				cell_node.add_child(newwall)
			# west wall
			if (west == null or west["floor_height"] > height or (north["type"] == 4 or north["type"] == 5)) and !(type == 2 or type == 4):
				var wallheight
				if west == null: wallheight = 16-height
				else: wallheight = west["floor_height"]-height
				var newwall = new_wall(UW.data["uw1"]["images"]["walls"][cell["wall_texture"]], wallheight)
				newwall.translation.x = -1
				newwall.rotation_degrees.y = 90
				newwall.translation.y = newfloor.translation.y
				cell_node.add_child(newwall)
			# east wall
			if (east == null or east["floor_height"] > height or (north["type"] == 4 or north["type"] == 5)) and !(type == 3 or type == 5):
				var wallheight
				if east == null: wallheight = 16-height
				else: wallheight = east["floor_height"]-height
				var newwall = new_wall(UW.data["uw1"]["images"]["walls"][cell["wall_texture"]], wallheight)
				newwall.translation.x = 1
				newwall.rotation_degrees.y = -90
				newwall.translation.y = newfloor.translation.y
				cell_node.add_child(newwall)
			# diagonal walls
			if type >= 2 and type <= 5:
				var wall_height = 16 - height
				var new_wall = new_wall_diagonal(UW.data["uw1"]["images"]["walls"][cell["wall_texture"]], wall_height)
				new_wall.translation.y = newfloor.translation.y
				if type == 3: new_wall.rotation_degrees.y = -90
				elif type == 4: new_wall.rotation_degrees.y = 90
				elif type == 5: new_wall.rotation_degrees.y = 180
				cell_node.add_child(new_wall)
					
				
			
			# done, add node to cells
			_cells.add_child(cell_node)

func new_floor(texture, type):
	var floormesh = floor_meshes[type].instance()
	var meshinstance = floormesh.get_node("MeshInstance")
	var material = UW.data["uw1"]["rotating_palette_spatial"].duplicate()
	material.set_shader_param("img", texture)
	meshinstance.set_surface_material(0, material)
	return floormesh

func new_wall(texture,height):
	var newwallmesh = wallmesh.instance()
	var meshinstance = newwallmesh.get_node("MeshInstance")
	var material = UW.data["uw1"]["rotating_palette_spatial"].duplicate()
	meshinstance.scale.y = height
	material.set_shader_param("img", texture)
	material.set_shader_param("scale", Vector2(1.0, 0.25*height))
	meshinstance.set_surface_material(0, material)
	return newwallmesh
	
func new_wall_diagonal(texture, height):
	var newwallmesh = walldiagmesh.instance()
	var meshinstance = newwallmesh.get_node("MeshInstance")
	var material = UW.data["uw1"]["rotating_palette_spatial"].duplicate()
	meshinstance.scale.y = height
	material.set_shader_param("img", texture)
	material.set_shader_param("scale", Vector2(1.0, 0.25*height))
	meshinstance.set_surface_material(0, material)
	return newwallmesh
