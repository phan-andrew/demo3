extends Node2D

var submitted = false
var vehicle

func _ready():
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

func _progress(speed):
	$ParallaxBackground.progress(speed)
