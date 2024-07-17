extends Node2D
var percent = 0
var total_segments = 0
var total_time = 0
var current_point = 0
var index = 2 
var current_time = 1
var submitted = false
var vehicle

func _ready():
	total_segments = str_to_var(Mitre.timeline_dict[0][0])
	total_time = str_to_var(Mitre.timeline_dict[0][1])
	vehicle = $sub

func _process(delta):
	if $ParallaxBackground/ParallaxLayer.progressing:
		vehicle.play("move")
	else:
		vehicle.play("hover")
	if Settings.theme == 0:
		$sub.show()
		$plane.hide()
		vehicle = $sub
		$ParallaxBackground/ParallaxLayer/background.texture = load("res://images/UI_images/progress_bar/underwater/Underwater Progress Bar.png")
	if Settings.theme == 1:
		$sub.hide()
		$plane.show()
		vehicle = $plane
		$ParallaxBackground/ParallaxLayer/background.texture = load("res://images/UI_images/progress_bar/air/Cloud Bar.png")



func _progress():
	if (current_point < total_segments):
		current_point = current_point + 1
		index = index + 1
		current_time = str_to_var(Mitre.timeline_dict[index][1])
	percent = percent + ((float(current_time)/total_time)*100)
	$ParallaxBackground.progress()
