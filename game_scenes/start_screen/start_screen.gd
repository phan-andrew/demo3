extends Node2D

func _ready():
	if Settings.changed_scene == 1:
		$mouse_click.playing = true
		Settings.changed_scene = 0

func _process(delta):
	pass

func _on_button_3_pressed():
	Settings.changed_scene = 1
	get_tree().change_scene_to_file("res://game_scenes/profiles_screen/profiles_screen.tscn")
	hide ()

func _on_button_pressed():
	Settings.changed_scene = 1
	get_tree().change_scene_to_file("res://game_scenes/options_screen/options_screen.tscn")
	hide ()

func _on_button_2_pressed():
	Settings.changed_scene = 1
	get_tree().change_scene_to_file("res://game_scenes/help_screen/help_screen.tscn")
	hide ()
