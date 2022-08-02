extends Node

const TILESIZE = 2 # size of tile height/width in 3d units

# enums
enum GAME_TYPE{NONE, UW1, UW2}
enum DIRECTION{NORTH,NORTHEAST,EAST,SOUTHEAST,SOUTH,SOUTHWEST,WEST,NORTHWEST}

# set the game type directories
var uw1_dir = "C:/Users/jasta/Documents/uw_data"
var uw2_dir = null

var image_scale = 4.0
var data = {"uw1":{}, "uw2":{}}
var current_data = null
var player = {"floor_level":0, "height":1.3}

func _ready():
	
	# init data loader
	var data_loader = load("res://engine/data_loader.gd").new()
	
	# get ULTIMA UNDERWORLD 1 data
	if uw1_dir != null:
		data["uw1"] = data_loader.load_uw1_data()
		current_data = data["uw1"]
		
	# if no game type was found
	if current_data == null:
		printerr("NO GAME TYPE DETECTED!")
		get_tree().quit()
	
	
	
	
