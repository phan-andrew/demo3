extends Node2D

var vehicle
var current_round = 2

func _ready():
	vehicle = $sub

func _process(_delta):
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
	$Label.text="T"+str(int(Mitre.timeline_dict[current_round][0]))
	$timeline_title.text=str(Mitre.timeline_dict[current_round][1])

func _progress(speed):
	$ParallaxBackground.progress(speed)
func increase_time():
	current_round=current_round+1
