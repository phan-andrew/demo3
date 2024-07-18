extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_continue_pressed():
	Settings.changed_scene = 1
	get_tree().change_scene_to_file("res://game_scenes/profiles_screen/profiles_screen.tscn")
	hide ()

func _on_button_pressed():
	Settings.changed_scene = 1
	get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
	hide ()
