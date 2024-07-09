extends Control

func _ready():
	pass

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
	hide()
