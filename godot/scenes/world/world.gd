extends Spatial

onready var _cells = $cells

func _ready():
	
	build_world_level(UW.data["uw1"], 0)

func build_world_level(uwdata, levelnum):
	
	var floormesh = preload("res://scenes/world/cell_shapes/floor.tscn")
	var tilesize = 2
	var map = uwdata["map"]
	var level = map["levels"][levelnum]
	
	# clear everything in the cells node
	for c in _cells.get_children():
		_cells.remove_child(c)
		c.queue_free()
	
	# build floor map from level data cells
	for y in range(0, level["cells"].size()):
		for x in range(0, level["cells"][y].size()):
			var cell = level["cells"][y][x]
			var type = cell["type"]
			var height = cell["floor_height"]
			
			# if solid cell, do nothing
			if type == 0: continue
			
			var newmesh = floormesh.instance()
			var meshinstance = newmesh.get_node("MeshInstance")
			var floor_material = UW.data["uw1"]["rotating_palette_spatial"].duplicate()
			newmesh.translation.x = x*tilesize
			newmesh.translation.z = y*tilesize
			newmesh.translation.y = height * tilesize * 0.25
			floor_material.set_shader_param("img", UW.data["uw1"]["images"]["floors"][cell["floor_texture"]])
			meshinstance.set_surface_material(0, floor_material)
			_cells.add_child(newmesh)
			
			
