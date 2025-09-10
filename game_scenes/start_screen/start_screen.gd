extends Node2D
var seacat=false

func _ready():
	$Sprite2D.texture = load(Settings.textured[Settings.theme])
	Music.start_music()
		
func _on_button_3_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/profiles_screen/profiles_screen.tscn")
	hide()

func _on_button_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/options_screen/options_screen.tscn")
	hide()

func _on_button_2_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/help_screen/help_screen.tscn")
	hide()

# ADD THIS NEW FUNCTION:
func _on_multiplayer_button_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://multiplayer_lobby.tscn")
	hide()

func _on_help_pressed():	
	pass

func _on_area_2d_mouse_entered():
	seacat=true 

func _on_area_2d_mouse_exited():
	seacat=false
