extends Node2D

var redmission = true
var bluemission = true

func _ready():
	$Continue.disabled = true 


func _process(delta):
	if redmission && bluemission:
		$Continue.disabled = false
	else:
		$Continue.disabled = true

func _on_continue_pressed():
	Music.mouse_click()
	if redmission && bluemission:
		get_tree().change_scene_to_file("res://game_scenes/profiles_screen/profiles_screen.tscn")
		hide ()

func _on_button_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
	hide ()

func _on_button_2_pressed():
	Mitre.red_objective = $TextEdit.text
	$Label4.text = "Saved"
	redmission = true

func _on_button_3_pressed():
	Mitre.blue_objective = $TextEdit2.text
	$Label5.text = "Saved"
	bluemission = true

func _on_text_edit_text_changed():
	$Label4.text = ""
	redmission = false

func _on_text_edit_2_text_changed():
	$Label5.text = ""
	bluemission = false

func _on_help_pressed():
	$Window.visible = true

func _on_window_close_requested():
	$Window.visible = false
