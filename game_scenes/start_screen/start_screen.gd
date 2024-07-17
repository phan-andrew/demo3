extends Node2D
var scene_path = "res://audio/audio.tscn" 
var scene = load(scene_path)
var child_node_path := NodePath("res://audio/audio.tscn")

func _ready():
	var child_node = get_node(child_node_path)

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
