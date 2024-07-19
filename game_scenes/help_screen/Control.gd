extends Control

func _ready():
	if Settings.changed_scene == 1:
		$mouse_click.playing = true
		Settings.changed_scene = 0
	
func _on_back_button_pressed():
	Settings.changed_scene = 1
	get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
	hide()

	

func _on_area_2d_mouse_shape_entered(shape_idx):
	print("sigma")
	get_tree().change_scene_to_file("res://Krishna test/cardthrow.tscn")
	hide()
