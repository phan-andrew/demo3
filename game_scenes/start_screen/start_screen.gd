extends Node2D

func _ready():
	Music.start_music()

func _process(delta):
	pass

func _on_button_3_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/mission_input_screen/mission_inputs.tscn")
	hide ()

func _on_button_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/options_screen/options_screen.tscn")
	hide ()

func _on_button_2_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/help_screen/help_screen.tscn")
	hide ()
