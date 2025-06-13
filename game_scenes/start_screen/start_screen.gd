extends Node2D
var seacar=false
func _ready():
	$Label.text="SEACAT"
	$Sprite2D.texture = load(Settings.textured[Settings.theme])
	Music.start_music()
		
	

func _process(delta):
	if seacar:
		$Label.text='SEACAR'
	else:
		$Label.text='SEACAT'

func _on_button_3_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/profiles_screen/profiles_screen.tscn")
	hide ()

func _on_button_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/options_screen/options_screen.tscn")
	hide ()

func _on_button_2_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/help_screen/help_screen.tscn")
	hide ()

func _on_help_pressed():
	pass # Replace with function body.

func _on_area_2d_mouse_entered():
	seacar=true 

func _on_area_2d_mouse_exited():
	seacar=false
