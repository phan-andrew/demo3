extends Node2D
var speed = 30
var playIcon = preload("res://images/UI_images/play_button.png")
var pauseIcon = preload("res://images/UI_images/pause_button.png")
var fastIcon = preload("res://images/UI_images/fast_forward_button.png")
var pauseB = false
var speedB = 1

func _ready():
	$Label.text = "Mission Statement\n\n" + Mitre.blue_objective + "\n\n\n\nOPFOR Mission Statement\n\n" + Mitre.red_objective
	Music.scroll_music(1)

func _process(delta):
	var velocity = Vector2(0, -speed)
	$Label.position += velocity * delta

func _on_back_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/prompts_screen/starting_prompts.tscn")
	hide ()
	
func _on_skip_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/game_screen/game_screen.tscn")
	hide ()

func _on_pause_pressed():
	if pauseB == false:
		pauseB = true
		$pause.icon = playIcon
		speed = 0
		Music.scroll_music(0)
	else:
		if speedB == 1:
			pauseB = false
			$pause.icon = pauseIcon
			speed = 30
			Music.scroll_music(1)
		if speedB == 2:
			pauseB = false
			$pause.icon = pauseIcon
			speed = 60
			Music.scroll_music(1.5)

func _on_speed_button_pressed():
	if speedB == 1:
		if pauseB == false:
			speed = 60
			speedB = 2
			Music.scroll_music(1.5)
		else:
			speedB = 2
	else:
		if pauseB == false:
			speed = 30
			speedB = 1
			Music.scroll_music(1)
		else:
			speedB = 1
