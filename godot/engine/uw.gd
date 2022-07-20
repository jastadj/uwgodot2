extends Node

var uw_dir = "C:/Users/jasta/Documents/uw_data"

var palettes = []
var aux_palettes = []
var images = {}

func _ready():
	
	print("Initializing UW...")
	
	# data loader (loads UW data assets)
	var data_loader = load("res://engine/data_loader.gd").new()
	var uw_data = str(uw_dir, "/UWDATA")
	
	# load palettes
	print("Loading palettes...")
	palettes = data_loader.load_palettes(str(uw_data,"/PALS.DAT"))
	print("Loaded ", palettes.size(), " palettes.")
	aux_palettes = data_loader.load_aux_palettes(str(uw_data,"/ALLPALS.DAT"))
	print("Loaded ", aux_palettes.size(), " aux palettes.")

	# load textures
	print("Loading textures...")
	images["walls"] = data_loader.load_textures(str(uw_data,"/W64.TR"))
	print("Loaded ", images["walls"].size(), " wall textures.")
	images["floors"] = data_loader.load_textures(str(uw_data,"/F32.TR"))
	print("Loaded ", images["floors"].size(), " floor textures.")
