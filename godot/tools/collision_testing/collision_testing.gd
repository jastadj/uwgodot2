extends Node2D

var move_speed = 500

onready var wall_lines = create_rect_lines(get_bbox($wall))
onready var player_lines = create_rect_lines(get_bbox($player))

func _ready():
	
	add_child(wall_lines)
	add_child(player_lines)

func _input(event):
	
	if event.is_action_pressed("ui_cancel"): get_tree().quit()

func _process(delta):
	
	#if wall_lines == null or player_lines == null: return
	
	var wallbbox = get_bbox($wall)
	var playerbbox = get_bbox($player)
	
	$CanvasLayer/wall_rect.text = str("wallbbox    :", wallbbox)
	$CanvasLayer/player_rect.text = str("playerbbox:", playerbbox)
	
	wall_lines.position = wallbbox.position
	player_lines.position = playerbbox.position

func _physics_process(delta):
	
	var prev_pos = $player.position
	var new_pos = prev_pos
	var move_input = Vector2()
	if Input.is_action_pressed("ui_up"): move_input.y = -1
	if Input.is_action_pressed("ui_down"): move_input.y = 1
	if Input.is_action_pressed("ui_left"): move_input.x = -1
	if Input.is_action_pressed("ui_right"): move_input.x = 1

	new_pos += move_input * move_speed * delta
	
	var wallbbox = get_bbox($wall)
	var playerbbox = get_bbox($player)
	var has_collisions = true
	
	while has_collisions:
		print("loop")
		if playerbbox.intersects(wallbbox):
			print(OS.get_ticks_msec(), ": has collision")
			new_pos = resolve_collision(wallbbox, playerbbox, prev_pos, new_pos)
			print("setting new bbox pos")
			playerbbox.position = new_pos
		else:
			print("collisions resolved")
			has_collisions = false
			break
	
	$player.position = new_pos

func resolve_collision(staticbb:Rect2, playerbb:Rect2, opos:Vector2, dpos:Vector2):
	var movevector = dpos - opos
	print("resolving collision")
	if movevector == Vector2(0,0): return opos
	
	if movevector.x < 0:
		playerbb.position.x = staticbb.position.x + staticbb.size.x + 2
	elif movevector.x > 0:
		playerbb.position.x = staticbb.position.x - playerbb.size.x - 2

	return Vector2(playerbb.position.x, playerbb.position.y )

func get_bbox(obj:Sprite):
	
	return Rect2(obj.position, obj.get_global_transform().get_scale() * obj.texture.get_size())
	
func create_rect_lines(rect:Rect2):
	var newlines = Line2D.new()
	newlines.width = 5
	newlines.add_point(Vector2(0,0))
	newlines.add_point(Vector2(rect.size.x, 0))
	newlines.add_point(Vector2(rect.size.x, rect.size.y))
	newlines.add_point(Vector2(0, rect.size.y))
	newlines.add_point(Vector2(0,0))
	return newlines
