extends Node2D

func _ready():
	pass

func _process(delta):
	pass

func _on_button_pressed():
	get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
	hide()

func _on_help_pressed():
	$Window.visible = true

func _on_window_close_requested():
	$Window.visible = false
