extends Node2D
var speed = 20
var playIcon = preload("res://images/UI_images/play_button.png")
var pauseIcon = preload("res://images/UI_images/pause_button.png")
var fastIcon = preload("res://images/UI_images/fast_forward_button.png")
var pauseB = false
var speedB = 1

func _ready():
	if Settings.changed_scene == 1:
		$mouse_click.playing = true
		Settings.changed_scene = 0
	$Label.text = "Mission Statement\n\n" + Mitre.blue_objective + "\n\n\n\nOPFOR Mission Statement\n\n" + Mitre.red_objective

func _process(delta):
	var velocity = Vector2(0, -speed)
	$Label.position += velocity * delta

func _on_back_pressed():
	Settings.changed_scene = 1
	get_tree().change_scene_to_file("res://game_scenes/prompts_screen/starting_prompts.tscn")
	hide ()
	
func _on_skip_pressed():
	Settings.changed_scene = 1
	get_tree().change_scene_to_file("res://game_scenes/game_screen/game_screen.tscn")
	hide ()

func _on_pause_pressed():
	if pauseB == false:
		pauseB = true
		$pause.icon = playIcon
		speed = 0
	else:
		if speedB == 1:
			pauseB = false
			$pause.icon = pauseIcon
			speed = 20
		if speedB == 2:
			pauseB = false
			$pause.icon = pauseIcon
			speed = 40

func _on_speed_button_pressed():
	if speedB == 1:
		if pauseB == false:
			speed = 40
			speedB = 2
		else:
			speedB = 2
	else:
		if pauseB == false:
			speed = 20
			speedB = 1
		else:
			speedB = 1
