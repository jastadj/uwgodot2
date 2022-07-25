extends Node

enum GAME_TYPE{NONE, UW1, UW2}

var game_type = GAME_TYPE.NONE

# set the game type directories
var uw1_dir = "C:/Users/jasta/Documents/uw_data"
var uw2_dir = null

var data = {"uw1":{}, "uw2":{}}

func _ready():
	
	# init data loader
	var data_loader = load("res://engine/data_loader.gd").new()
	
	# get ULTIMA UNDERWORLD 1 data
	if uw1_dir != null:
		game_type = GAME_TYPE.UW1
		data["uw1"] = data_loader.load_uw1_data()
		
		
	# if no game type was found
	if game_type == GAME_TYPE.NONE:
		printerr("NO GAME TYPE DETECTED!")
		get_tree().quit()
	
	
	
	
