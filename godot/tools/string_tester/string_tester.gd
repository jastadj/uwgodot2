extends Control


var current_game = null
var current_block = null
onready var _game_type_list = $PanelContainer/game_type_list
onready var _blocks_list = $PanelContainer/string_blocks
onready var _strings = $strings

func _ready():
	
	# add game types to list
	for game in UW.data.keys():
		_game_type_list.add_item(game)
	
	# connect list select
	_game_type_list.connect("item_selected", self, "_on_game_type_selected")
	_blocks_list.connect("item_selected", self, "_on_string_block_selected")

	# select first game in the list by default
	if _game_type_list.get_item_count() > 0: _on_game_type_selected(0)
	
func _on_game_type_selected(item):
	
	var game_string
	
	if item == null or item == -1:
		current_game = null
		_update_blocks_list()
		return
	game_string = _game_type_list.get_item_text(item)
	current_game = UW.data[game_string]
	
	# update blocks list
	_update_blocks_list()
	
func _update_blocks_list():
	
	# clear entries from list
	_blocks_list.clear()
	
	if current_game == null: return
	
	# add the string block ids to the list
	for strblk in current_game["strings"]:
		_blocks_list.add_item(str(strblk["block_id"]))

func _on_string_block_selected(item):
	
	var itemtext = _blocks_list.get_item_text(item)
	
	current_block = null
	
	# find block id in blocks list
	for stringblock in current_game["strings"]:
		if str(stringblock["block_id"]) == itemtext:
			current_block = stringblock
	
	if current_block == null:
		printerr(str("string block tester: could not find block id in list:",itemtext) )
	else:
		_update_strings()
		
func _update_strings():
	
	_strings.clear()
	
	if current_block == null: return
	
	for string in current_block["strings"]:
		_strings.add_item(string)
		
