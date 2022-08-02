extends Control

var left_images = []
var right_images = []

func _ready():
	
	# create list of scroll edge images
	for i in range(0,5):
		left_images.push_back(UW.current_data["images"]["scroll"][i])
		right_images.push_back(UW.current_data["images"]["scroll"][i+5])
	
	# position edges onto the ui
	$scroll_left.rect_position = Vector2(11,169)
	$scroll_right.rect_position = $scroll_left.rect_position + Vector2(295,0)
	
	update_scroll()
	
func update_scroll():
	$scroll_left.texture = left_images[0]
	$scroll_right.texture = right_images[0]
