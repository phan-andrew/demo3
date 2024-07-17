extends Control
@export
var bus_name = "Master"
var bus_index = 1

func _ready():
	bus_index = AudioServer.get_bus_index(bus_name)
	$HSlider.value = Settings.audio_value

func _process(delta):
	pass

func _on_button_pressed():
	get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
	hide()

func _on_h_slider_value_changed(value):
	Settings.audio_value = value
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
