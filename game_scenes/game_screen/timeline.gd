extends Node2D

var submitted = false
var vehicle
var timelabel

func _ready():
	vehicle = $sub
	timelabel = int(Mitre.timeline_dict[2][0])

func _process(delta):
	if $ParallaxBackground/ParallaxLayer.progressing:
		vehicle.play("move")
	else:
		vehicle.play("hover")
	if Settings.theme == 0:
		$sub.show()
		$tank.hide()
		$plane.hide()
		vehicle = $sub
		$ParallaxBackground/ParallaxLayer/background.texture = load("res://images/UI_images/progress_bar/underwater/Underwater Progress Bar.png")
	if Settings.theme == 1:
		$sub.hide()
		$plane.show()
		$tank.hide()
		vehicle = $plane
		$ParallaxBackground/ParallaxLayer/background.texture = load("res://images/UI_images/progress_bar/air/Cloud Bar.png")
	if Settings.theme == 2:
		$sub.hide()
		$plane.hide()
		$tank.show()
		vehicle = $tank
		$ParallaxBackground/ParallaxLayer/background.texture = load("res://images/UI_images/progress_bar/land/Surface.png")
	$Label.text = "T" + str(timelabel)

func _progress(speed):
	$ParallaxBackground.progress(speed)
	
