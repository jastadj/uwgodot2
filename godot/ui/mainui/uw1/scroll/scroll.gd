extends Control

onready var scroll_edges = $scroll_edges

func _ready():
	
	# create scroll background texture
	var scrollbg = Image.new()
	var scrollbgtexture = ImageTexture.new()
	scrollbg.create(291,30,false, Image.FORMAT_RGBA8)
	scrollbg.fill(UW.current_data["palettes"][0][42])
	scrollbgtexture.create_from_image(scrollbg)
	$scroll_background.rect_position = Vector2(15,169)
	$scroll_background.texture = scrollbgtexture
	
	
