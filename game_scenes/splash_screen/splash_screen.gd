extends Node2D

func _ready():
	_change_scene_delay()

func _process(delta):
	pass

func _change_scene_delay():
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
	hide()
