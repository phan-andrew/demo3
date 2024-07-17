extends Node2D
var simultaneous_scene = preload("res://audio/audio.tscn").instantiate()

func _ready():
	#get_tree().root.add_child("res://audio/audio.tscn").$AudioStreamPlayer2.playing = true
	pass

func _process(delta):
	pass

func _on_button_3_pressed():
	get_tree().change_scene_to_file("res://game_scenes/profiles_screen/profiles_screen.tscn")
	hide ()

func _on_button_pressed():
	get_tree().change_scene_to_file("res://game_scenes/options_screen/options_screen.tscn")
	hide ()

func _on_button_2_pressed():
	get_tree().change_scene_to_file("res://game_scenes/help_screen/help_screen.tscn")
	hide ()
