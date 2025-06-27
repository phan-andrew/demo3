extends Node2D

var vehicle
var current_round = 2
var round_end = Mitre.timeline_dict.size()-2

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

func _on_area_2d_mouse_entered():
	$CanvasLayer/PanelContainerCurrent.show()
	$CanvasLayer/PanelContainerCurrent/MarginContainer/Label.text="Round: " + str(current_round-1) + " of " + str(round_end) + "\n" + "Time: "+str(Mitre.timeline_dict[current_round][0]) +  "\n" + "Description: " + str(Mitre.timeline_dict[current_round][1]) + "\n" + "Subsystems not in Play: " + str(Mitre.timeline_dict[current_round][2])
	
func _on_area_2d_mouse_exited():
	$CanvasLayer/PanelContainerCurrent.hide()

func _on_start_area_2d_mouse_entered():
	var previous_round = current_round-1
	if previous_round-1 != 0:
		$StartCanvasLayer/PanelContainerCurrent.show()
		$StartCanvasLayer/PanelContainerCurrent/MarginContainer/Label.text="Round: " + str(previous_round-1) + " of " + str(round_end) + "\n" + "Time: "+str(Mitre.timeline_dict[previous_round][0]) +  "\n" + "Description: " + str(Mitre.timeline_dict[previous_round][1]) + "\n" + "Subsystems not in Play: " + str(Mitre.timeline_dict[previous_round][2])
	else:
		$StartCanvasLayer/PanelContainerStart.show()

func _on_start_area_2d_mouse_exited():
	$StartCanvasLayer/PanelContainerCurrent.hide()
	$StartCanvasLayer/PanelContainerStart.hide()

func _on_end_area_2d_mouse_entered() -> void:
	var next_round = current_round+1
	if next_round <= round_end+1:
		$EndCanvasLayer/PanelContainerCurrent.show()
		$EndCanvasLayer/PanelContainerCurrent/MarginContainer/Label.text="Round: " + str(next_round-1) + " of " + str(round_end) + "\n" + "Time: "+str(Mitre.timeline_dict[next_round][0]) +  "\n" + "Description: " + str(Mitre.timeline_dict[next_round][1]) + "\n" + "Subsystems not in Play: " + str(Mitre.timeline_dict[next_round][2])
	else:
		$EndCanvasLayer/PanelContainerEnd.show()

func _on_end_area_2d_mouse_exited() -> void:
	$EndCanvasLayer/PanelContainerCurrent.hide()
	$EndCanvasLayer/PanelContainerEnd.hide()
