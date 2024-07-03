extends Control
@export
var bus_name = "Master"
var bus_index = 0

func _ready():
	pass


func _process(delta):
	pass


func _on_h_slider_value_changed(value):
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


func _on_button_pressed():
	pass
