extends Control
@export
var bus_name = "music"
var bus_index = 1

var bus2_name = "effects"
var bus2_index = 1

func _ready():
	$Sprite2D2.texture = load(Settings.textured[Settings.theme])
	bus_index = AudioServer.get_bus_index(bus_name)
	$HSlider.value = Settings.music_value
	bus2_index = AudioServer.get_bus_index(bus2_name)
	$HSlider2.value = Settings.sound_effects
	$Theme_select.selected = Settings.theme
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
	Music.change_theme()
	$Sprite2D2.texture = load(Settings.textured[Settings.theme])


func _on_h_slider_2_value_changed(value):
	Settings.sound_effects = value
	AudioServer.set_bus_volume_db(bus2_index, linear_to_db(value))
