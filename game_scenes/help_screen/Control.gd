extends Control

func _ready():
	$Sprite2D2.texture = load(Settings.textured[Settings.theme])
	
func _on_back_button_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
	hide()

func _on_area_2d_mouse_shape_entered(shape_idx):
	get_tree().change_scene_to_file("res://Krishna test/cardthrow.tscn")
	hide()
