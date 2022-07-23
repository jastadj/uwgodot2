extends Control

var current_game = null
var current_font = null

onready var _game_type_list = $PanelContainer/VBoxContainer/game_type_list
onready var _font_list = $PanelContainer/VBoxContainer/font_list
onready var _info = $PanelContainer/VBoxContainer/info
onready var _font_line = $font_line
onready var _text_input = $text_input

func _ready():
	
	# add game types to list
	for game in UW.data.keys():
		_game_type_list.add_item(game)
	
	# connect list select
	_game_type_list.connect("item_selected", self, "_on_game_type_selected")
	_font_list.connect("item_selected", self, "_on_font_selected")

	# connect text input
	_text_input.connect("text_changed", self, "_on_input_text_changed")

	# select first game in the list by default
	if _game_type_list.get_item_count() > 0: _on_game_type_selected(0)
	
func _on_game_type_selected(item):
	
	var game_string
	
	if item == null or item == -1: return
	game_string = _game_type_list.get_item_text(item)
	current_game = UW.data[game_string]
	
	_update_font_list()

func _on_font_selected(item):
	
	if item == null or item == -1:
		current_font = null
	else:
		current_font = current_game["fonts"][item]
	
	_update_font()
	
func _update_font_list():
	
	# clear font list
	_font_list.clear()
	
	for i in range(current_game["fonts"].size()):
		_font_list.add_item(str(i))

func _update_font():
	
	# if font is not valid, hide font info and font display
	if current_font == null:
		_info.hide()
		# need to also hide font display
		return
	
	# otherwise show the font info
	_info.show()
	
	# update info text
	_info.get_node("char_count").text = str("CHAR COUNT: ", current_font["chars"].size())
	_info.get_node("font_height").text = str("FONT HEIGHT: ", current_font["height"])
	_info.get_node("max_width").text = str("MAX WIDTH: ", current_font["max_width"])
	_info.get_node("blank_width").text = str("BLANK WIDTH: ", current_font["blank_width"])
	_info.get_node("row_width").text = str("ROW WIDTH: ", current_font["row_width"])
	
	_update_font_string()
	
func _update_font_string():
	
	# clear font line
	for ch in _font_line.get_children():
		ch.queue_free()
		_font_line.remove_child(ch)
	
	# if no valid font, return
	if current_font == null: return
	
	# create ascii string from text to use as indexing into char list
	var ascii_string = _text_input.text.to_ascii()
	
	# build list of characters from ascii string
	for ch in ascii_string:
		if ch >= current_font["chars"].size(): continue
		var newimg = TextureRect.new()
		var newimgtxt = ImageTexture.new()
		newimgtxt.create_from_image(current_font["chars"][ch], 0)
		newimg.texture = newimgtxt 
		_font_line.add_child(newimg)

func _on_input_text_changed(change):
	
	_update_font_string()
