extends Label
var speed = 13
var playIcon = preload("res://images/UI_images/play_button.png")
var pauseIcon = preload("res://images/UI_images/pause_button.png")
var fastIcon = preload("res://images/UI_images/fast_forward_button.png")

func _ready():
	pass

func _process(delta):
	var velocity = Vector2(0, -speed)
	position += velocity * delta

func _on_back_pressed():
	Settings.changed_scene = 1
	get_tree().change_scene_to_file("res://game_scenes/prompts_screen/starting_prompts.tscn")
	hide ()

func _on_skip_pressed():
	Settings.changed_scene = 1
	get_tree().change_scene_to_file("res://game_scenes/game_screen/game_screen.tscn")
	hide ()


func _on_pause_pressed():
	pass # Replace with function body.


func _on_speed_button_pressed():
	pass # Replace with function body.
