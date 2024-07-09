extends Control

func _ready():
	pass

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://start_screen.tscn")
	hide()
