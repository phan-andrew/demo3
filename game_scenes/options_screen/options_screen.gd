extends Control
@export
var bus_name = "music"
var bus_index = 1

var bus2_name = "effects"
var bus2_index = 1

func _ready():
	bus_index = AudioServer.get_bus_index(bus_name)
	$HSlider.value = Settings.music_value
	bus2_index = AudioServer.get_bus_index(bus2_name)
	$HSlider2.value = Settings.sound_effects
	$Theme_select.selected = Settings.theme
	$theme.stream = preload("res://audio/themes/sea.mp3")
	$theme.play()
	Color(0.0, 0.25, 0.5)

func _process(delta):
	pass

func _on_button_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
	hide()

func _on_h_slider_value_changed(value):
	Settings.music_value = value
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _on_theme_select_item_selected(index):
	Settings.theme = index
	
	if index == 0:
		$theme.stream = preload("res://audio/themes/sea.mp3")
		$theme.volume_db = 0
		$bg.modulate = Color(0.0, 0.25, 0.5)
	if index == 1:
		$theme.stream = preload("res://audio/themes/air.mp3")
		$theme.volume_db = 2
		$bg.modulate = Color(0.146, 0.372, 0.959)
	if index == 2:
		$theme.stream = preload("res://audio/themes/land.mp3")
		$theme.volume_db = 0
		$bg.modulate = Color(0.552, 0.415, 0.161)
	$theme.play()

func _on_h_slider_2_value_changed(value):
	Settings.sound_effects = value
	AudioServer.set_bus_volume_db(bus2_index, linear_to_db(value))
