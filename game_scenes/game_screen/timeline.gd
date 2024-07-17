extends Node2D
var percent = 0
var total_segments = 0
var total_time = 0
var current_point = 0
var index = 2 
var current_time = 1
var submitted = false

func _ready():
	total_segments = str_to_var(Mitre.timeline_dict[0][0])
	total_time = str_to_var(Mitre.timeline_dict[0][1])

func _process(delta):
	pass



func _progress():
	if (current_point < total_segments):
		current_point = current_point + 1
		index = index + 1
		current_time = str_to_var(Mitre.timeline_dict[index][1])
	percent = percent + ((float(current_time)/total_time)*100)
	$ParallaxBackground/ParallaxLayer.progress()


func _on_submit_button_pressed():
	submitted = true
	_progress()
	
	
