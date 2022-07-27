extends Spatial



onready var _cells = $cells
var level = null
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
var wallslopeleftmesh = preload("res://scenes/world/cell_shapes/wall_slope_left.tscn")
var wallsloperightmesh = preload("res://scenes/world/cell_shapes/wall_slope_right.tscn")

# the build matrix rows are directions (n,e,s,w), the cols are adjacent cell type
# 0 = full wall
# 1 = wall if floor delta
# 3 = floor delta + 1 (leading edge of slope tile)
# 5 = floor delta + slope wall (triangle wall)
enum BUILD_FLAGS{FULL_WALL=0, FLOOR_DELTA=1, FLOOR_DELTA_LIP=3, FLOOR_DELTA_SOPE=5}
var buildmatrix = {
	UW.DIRECTION.NORTH:[0,1,1,1,0,0,1,3,5,5],
	UW.DIRECTION.EAST:[ 0,1,0,1,0,1,5,5,1,3],
	UW.DIRECTION.SOUTH:[0,1,0,0,1,1,3,1,5,5],
	UW.DIRECTION.WEST:[ 0,1,1,0,1,0,5,5,3,1]
	}



func _ready():
	
	build_world_level(UW.current_data, UW.player["floor_level"])

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
	level = map["levels"][levelnum]
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
	cell_node.translation.x = x*UW.TILESIZE
	cell_node.translation.z = y*UW.TILESIZE

	# build floor
	cell_node.add_child(build_cell_floor(cell))
	
	# build ceiling
	cell_node.add_child(build_cell_ceiling(cell))
	
	# build walls
	var walls = build_cell_walls(cell, get_adjacent_cells(cell, level))
	if walls: cell_node.add_child(walls)
	


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
	floormesh.translation.y = cell["floor_height"] * UW.TILESIZE * 0.25
	floor_node.name = "floor"
	floor_node.add_child(floormesh)
	return floor_node

func build_cell_ceiling(cell):
	var ceil_node = Spatial.new()
	var texture = UW.current_data["images"]["floors"][ cell["ceil_texture"] ]
	# ceil mesh / material
	var ceilmesh = floor_meshes[1].instance()
	var meshinstance = ceilmesh.get_node("MeshInstance")
	var material = UW.current_data["rotating_palette_spatial"].duplicate()
	material.set_shader_param("img", texture)
	meshinstance.set_surface_material(0, material)
	# flip ceiling to face down
	ceilmesh.rotation_degrees.x = 180
	# adjust ceil height
	ceilmesh.translation.y = 16 * UW.TILESIZE * 0.25
	ceil_node.name = "ceiling"
	ceil_node.add_child(ceilmesh)
	return ceil_node	

func build_cell_walls(cell, adjacent):
	
	var type = cell["type"]
	var floor_height = cell["floor_height"]
	var walls_node = Spatial.new()
	var material = UW.current_data["rotating_palette_spatial"].duplicate()
	
	# init walls node
	walls_node.name = "walls"
	# set wall material texture
	material.set_shader_param("img", UW.current_data["images"]["walls"][ cell["wall_texture"] ])
	
	
	# if this cell is diagonal, always build this wall
	if type >= 2 and type <= 5:
		var wall_height = 16 - floor_height
		# create mes h/material
		var newwallmesh = walldiagmesh.instance()
		var meshinstance = newwallmesh.get_node("MeshInstance")
		var newmaterial = material.duplicate()
		meshinstance.scale.y = wall_height
		newmaterial.set_shader_param("scale", Vector2(1.0, 0.25*wall_height))
		meshinstance.set_surface_material(0, newmaterial)
		# position/rotate mesh
		newwallmesh.translation.y = floor_height * UW.TILESIZE * 0.25
		if type == 3: newwallmesh.rotation_degrees.y = -90
		elif type == 4: newwallmesh.rotation_degrees.y = 90
		elif type == 5: newwallmesh.rotation_degrees.y = 180
		walls_node.add_child(newwallmesh)
	
	# check every direction and build the wall parts
	for d in adjacent.keys():
		var wall_height
		var buildflag = 0
		
		# don't draw certain walls for diagonal cell types
		if type == 2 and (d == UW.DIRECTION.NORTH or d == UW.DIRECTION.WEST): continue
		elif type == 3 and (d == UW.DIRECTION.NORTH or d == UW.DIRECTION.EAST): continue
		elif type == 4 and (d == UW.DIRECTION.SOUTH or d == UW.DIRECTION.WEST): continue
		elif type == 5 and (d == UW.DIRECTION.SOUTH or d == UW.DIRECTION.EAST): continue
		
		
		# if adjacent tile isn't null, get the adjacent tile type
		# and check what the build rule is
		if adjacent[d] != null:
			buildflag = buildmatrix[d][adjacent[d]["type"]]
		
		# if making a full wall, get the wall height from the ceil to floor
		if buildflag == BUILD_FLAGS.FULL_WALL: wall_height = 16 - floor_height
		# otherwise, get the delta between the floor heights
		else:
			wall_height = adjacent[d]["floor_height"] - floor_height
			if buildflag == BUILD_FLAGS.FLOOR_DELTA_LIP: wall_height += 1
		
		# if the wall height is above 0, make a wall
		if wall_height > 0:
			var newwall = wallmesh.instance()
			# set mesh material
			var mesh = newwall.get_node("MeshInstance")
			var mat = material.duplicate()
			var scaling = wall_height
			mat.set_shader_param("scale", Vector2(1.0, scaling*0.25))
			mesh.set_surface_material(0, mat)
			# rotate,scale,position mesh
			newwall.scale.y = scaling
			newwall.rotation_degrees.y = (d/2)*(-90)
			newwall.translation.y = floor_height*UW.TILESIZE*0.25
			
			match d:
				UW.DIRECTION.NORTH: newwall.translation.z = -1
				UW.DIRECTION.EAST: newwall.translation.x = 1
				UW.DIRECTION.SOUTH: newwall.translation.z = 1
				UW.DIRECTION.WEST: newwall.translation.x = -1
			walls_node.add_child(newwall)
			
		# if the adjacent cell has a perpendicular sloping floor
		# and the height is >= 0, make a slope wall to to cover up
		# the side of the ramp
		if wall_height >= 0 and adjacent[d]:
			if buildmatrix[d][adjacent[d]["type"]] == 5: 
				var newwallslope = null
				var mesh
				var mat = material.duplicate()
				
				#06      Sloping up to the north
				#07      Sloping up to the south
				#08      Sloping up to the east
				#09      Sloping up to the west
				
				# determine wall slope direction (left or right, going upwards)
				if d == UW.DIRECTION.NORTH and adjacent[d]:
					if adjacent[d]["type"] == 9: newwallslope = wallslopeleftmesh.instance()
					elif adjacent[d]["type"] == 8: newwallslope = wallsloperightmesh.instance()
				elif d == UW.DIRECTION.EAST and adjacent[d]:
					if adjacent[d]["type"] == 6: newwallslope = wallslopeleftmesh.instance()
					elif adjacent[d]["type"] == 7: newwallslope = wallsloperightmesh.instance()
				elif d == UW.DIRECTION.SOUTH and adjacent[d]:
					if adjacent[d]["type"] == 8: newwallslope = wallslopeleftmesh.instance()
					elif adjacent[d]["type"] == 9: newwallslope = wallsloperightmesh.instance()
				elif d == UW.DIRECTION.WEST and adjacent[d]:
					if adjacent[d]["type"] == 7: newwallslope = wallslopeleftmesh.instance()
					elif adjacent[d]["type"] == 6: newwallslope = wallsloperightmesh.instance()
					
				mesh = newwallslope.get_node("MeshInstance")
				mesh.set_surface_material(0, mat)
				
				# rotate, position mesh
				newwallslope.rotation_degrees.y = (d/2)*(-90)
				newwallslope.translation.y = (floor_height+wall_height)*UW.TILESIZE*0.25
				
				match d:
					UW.DIRECTION.NORTH: newwallslope.translation.z = -1
					UW.DIRECTION.EAST: newwallslope.translation.x = 1
					UW.DIRECTION.SOUTH: newwallslope.translation.z = 1
					UW.DIRECTION.WEST: newwallslope.translation.x = -1
				
				walls_node.add_child(newwallslope)
			
	if walls_node.get_child_count() == 0: return null
	return walls_node
	
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
	meshinstance.translation.y = floor_height * UW.TILESIZE * 0.25
	if type == 3: meshinstance.rotation_degrees.y = -90
	elif type == 4: meshinstance.rotation_degrees.y = 90
	elif type == 5: meshinstance.rotation_degrees.y = 180
	
	return meshinstance
	

