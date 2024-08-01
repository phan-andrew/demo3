extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.texture = load(Settings.textured[Settings.theme])
	$SaveResults.filters = ["*.csv"]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_save_button_pressed():
	Music.mouse_click()
	$SaveResults.current_dir = Mitre.downloadpath
	$SaveResults.current_file = "CTT_results_" + get_military_time() + "_" + Time.get_date_string_from_system()
	$SaveResults.popup_centered()

func get_military_time():
	# Get the current date and time
	var datetime = Time.get_datetime_dict_from_system()
	
	# Extract hour and minute
	var hour = str(datetime["hour"]).pad_zeros(2)
	var minute = str(datetime["minute"]).pad_zeros(2)
	
	# Format as HHMM
	var military_time = hour + minute
	return military_time

func _on_end_game_pressed():
	Music.mouse_click()
	get_tree().quit()

func _on_same_profile_pressed():
	Music.mouse_click()
	TransitionScene.transition()
	await TransitionScene.on_transition_finished
	get_tree().change_scene_to_file("res://game_scenes/game_screen/game_screen.tscn")
	hide ()

func _on_change_profile_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/prompts_screen/starting_prompts.tscn")
	hide ()

func _on_file_location_selected(path):
	var src_file = FileAccess.open("res://data/game_data.txt", FileAccess.ModeFlags.READ)
	if src_file == null:
		$Label.text = "Failed to find source"
		return
	
	var data = src_file.get_buffer(src_file.get_length())
	src_file.close()
	var dest_file = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if dest_file == null:
		$Label.text = "Failed to open destination file."
		return

	# Write the data to the destination file
	dest_file.store_buffer(data)
	dest_file.close()
	$Label.text = "File saved successfully at: " + path
