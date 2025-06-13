extends Control

func _ready():
	$Sprite2D2.texture = load(Settings.textured[Settings.theme])
	
func _on_back_button_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
	hide()
