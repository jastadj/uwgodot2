extends Node

var world = null

func _ready():
	
	world = get_parent()

func _resolve_bounding_box_collision(static_bb:Rect2, bb:Rect2, dir:Vector2):
	if dir.x < 0:
		bb.position.x = static_bb.position.x + static_bb.size.x + 0.1
	elif dir.x > 0:
		bb.position.x = static_bb.position.x - bb.size.x - 0.1
	
	if dir.y < 0:
		bb.position.y = static_bb.position.y + static_bb.size.y + 0.1
	elif dir.y > 0:
		bb.position.y = static_bb.position.y - bb.size.y - 0.1
		
	return bb
	
func resolve_world_collisions(origin:Vector3, dest:Vector3, dir:Vector2, bbox:Rect2):
	
	var cell_x = int(origin.x/UW.TILESIZE)
	var cell_y = int(origin.z/UW.TILESIZE)
	#var ocell = world.get_cell(Vector2(cell_x,cell_y))
	
	# get center and surrounding cell bounding boxes and resolve collisions
	for sy in range(cell_y-1, cell_y+2):
		for sx in range(cell_x-1, cell_x+2):
			var tcell = world.get_cell(Vector2(sx,sy))
			var cellbbox = world.get_cell_bounding_box(Vector2(sx,sy))
			if cellbbox != null:
				if bbox.intersects(cellbbox):
					if tcell["type"] == 0:
						bbox = _resolve_bounding_box_collision(cellbbox, bbox, dir)
	
	return Vector3(bbox.position.x + (bbox.size.x/2), dest.y, bbox.position.y + (bbox.size.y/2))
