extends Node2D
var seacar=false
func _ready():
	$Label.text="SEACAT"
	$Sprite2D.texture = load(Settings.textured[Settings.theme])
	Music.start_music()
	var file= FileAccess.open("res://missionstatements.txt", FileAccess.READ)
	if file:
		Mitre.red_objective=str(file.get_line())
		Mitre.blue_objective=str(file.get_line())
		Mitre.preloadedmission=true
	else: 
		Mitre.preloadedmission=false
		
	

func _process(delta):
	if seacar:
		$Label.text='SEACAR'

func _on_button_3_pressed():
	Music.mouse_click()
	if !Mitre.preloadedmission:
		get_tree().change_scene_to_file("res://game_scenes/mission_input_screen/mission_inputs.tscn")
		hide ()
	else:
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


func _on_area_2d_area_entered(area):
	seacar=true


func _on_area_2d_mouse_entered():
	seacar=true
