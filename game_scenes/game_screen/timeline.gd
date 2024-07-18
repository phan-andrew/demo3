extends Node2D

var submitted = false
var vehicle
var timeline = {}
var timelabel

func _ready():
	vehicle = $sub
	_on_start_timeline()
	timelabel = int(timeline[2][0])
	$Label.text = "T" + str(timelabel)

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

func _progress(speed):
	$ParallaxBackground.progress(speed)

func _on_start_timeline():
	var file= FileAccess.open("res://data/example_mission_timeline.txt", FileAccess.READ)
	while !file.eof_reached():
		var mission = Array(file.get_csv_line())
		timeline[timeline.size()] = mission
	file.close()
