extends Node2D

var vehicle
var current_round = 0
var round_end = Mitre.timeline_dict.size()-2

func _ready():
	vehicle = $sub

	var label = $timeline/timeline_title

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
	
	# Safe access to timeline_dict
	if is_valid_round(current_round):
		$Label.text = "T" + str(int(Mitre.timeline_dict[current_round][0]))
		if $CanvasLayer/UIHeader.has_node("timeline_title"):
			$CanvasLayer/UIHeader/timeline_title.text = str(Mitre.timeline_dict[current_round][1])




func _progress(speed):
	$ParallaxBackground.progress(speed)

func increase_time():
	current_round = current_round + 1

func _on_area_2d_mouse_entered():
	if is_valid_round(current_round):
		$CanvasLayer/PanelContainerCurrent.show()
		$CanvasLayer/PanelContainerCurrent/MarginContainer/Label.text = "Round: " + str(current_round) + " of " + str(round_end) + "\n" + "Description: " + str(Mitre.timeline_dict[current_round][2]) + "\n" + "Subsystems not in Play: " + str(Mitre.timeline_dict[current_round][3])

func _on_area_2d_mouse_exited():
	$CanvasLayer/PanelContainerCurrent.hide()

func _on_start_area_2d_mouse_entered():
	var previous_round = current_round - 1
	
	# Check if previous_round is valid (>= 0 and exists in dictionary)
	if previous_round >= 0 and is_valid_round(previous_round):
		$StartCanvasLayer/PanelContainerCurrent.show()
		$StartCanvasLayer/PanelContainerCurrent/MarginContainer/Label.text = "Round: " + str(previous_round) + " of " + str(round_end) + "\n" + "Time: " + str(Mitre.timeline_dict[previous_round][0]) + "\n" + "Description: " + str(Mitre.timeline_dict[previous_round][1]) + "\n" + "Subsystems not in Play: " + str(Mitre.timeline_dict[previous_round][2])
	else:
		# Show start panel when we're at the beginning
		$StartCanvasLayer/PanelContainerStart.show()

func _on_start_area_2d_mouse_exited():
	$StartCanvasLayer/PanelContainerCurrent.hide()
	$StartCanvasLayer/PanelContainerStart.hide()

func _on_end_area_2d_mouse_entered() -> void:
	var next_round = current_round + 1
	
	# Check if next_round is valid and within bounds
	if next_round <= round_end and is_valid_round(next_round):
		$EndCanvasLayer/PanelContainerCurrent.show()
		$EndCanvasLayer/PanelContainerCurrent/MarginContainer/Label.text = "Round: " + str(next_round) + " of " + str(round_end) + "\n" + "Time: " + str(Mitre.timeline_dict[next_round][0]) + "\n" + "Description: " + str(Mitre.timeline_dict[next_round][1]) + "\n" + "Subsystems not in Play: " + str(Mitre.timeline_dict[next_round][2])
	else:
		# Show end panel when we're at the end
		$EndCanvasLayer/PanelContainerEnd.show()

func _on_end_area_2d_mouse_exited() -> void:
	$EndCanvasLayer/PanelContainerCurrent.hide()
	$EndCanvasLayer/PanelContainerEnd.hide()

func is_valid_round(round_index: int) -> bool:
	"""Check if the round index is valid for accessing Mitre.timeline_dict"""
	# Check if Mitre exists
	if not Mitre:
		print("Warning: Mitre not available")
		return false
	
	# Check if timeline_dict exists
	if not Mitre.timeline_dict:
		print("Warning: Mitre.timeline_dict not available")
		return false
	
	# Check if the round index exists in the dictionary
	if not Mitre.timeline_dict.has(round_index):
		print("Warning: Round index ", round_index, " not found in timeline_dict")
		return false
	
	# Check if the round data has the required elements
	var round_data = Mitre.timeline_dict[round_index]
	if not round_data or round_data.size() < 3:
		print("Warning: Invalid round data at index ", round_index, " - insufficient data")
		return false
	
	return true
