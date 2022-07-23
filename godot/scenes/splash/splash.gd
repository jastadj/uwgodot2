extends Node2D

var current_menu = null

func _ready():
	
	$CanvasLayer/buttons/image_tester_button.connect("pressed", self, "_on_image_tester_button_pressed")
	$CanvasLayer/buttons/font_tester_button.connect("pressed", self, "_on_font_tester_button_pressed")

func _input(event):
	
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(current_menu):
			current_menu.queue_free()
			current_menu = null
		else:
			get_tree().quit()

func _on_image_tester_button_pressed():
	if current_menu == null:
		current_menu = preload("res://tools/image_tester/image_tester.tscn").instance()
		$CanvasLayer.add_child(current_menu)

func _on_font_tester_button_pressed():
	if current_menu == null:
		current_menu = preload("res://tools/font_tester/font_tester.tscn").instance()
		$CanvasLayer.add_child(current_menu)
