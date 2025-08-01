extends Node2D
var CTT_title 
@onready var attack_button = $Button
@onready var defend_button = $Button2
@onready var timeline_button = $Button4
@onready var file_dialog = $FileDialog
@onready var file_dialog2 = $FileDialog2
@onready var file_dialog3 = $FileDialog3
@onready var alabel = $attackfilelabel
@onready var dlabel = $defendfilelabel
@onready var tlabel = $timelinefilelabel
var attackfile = false
var defendfile = false
var timelinefile = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.texture = load(Settings.textured[Settings.theme])
	Music.start_music()
	attack_button.connect("pressed", Callable(self, "_on_attack_button_pressed"))
	defend_button.connect("pressed", Callable(self, "_on_defend_button_pressed"))
	timeline_button.connect("pressed", Callable(self, "_on_timeline_button_pressed"))
	file_dialog.connect("file_selected", Callable(self, "_on_attack_file_selected"))
	file_dialog2.connect("file_selected", Callable(self, "_on_defend_file_selected"))
	file_dialog3.connect("file_selected", Callable(self, "_on_timeline_file_selected"))
	alabel.text = "Not Selected"
	dlabel.text = "Not Selected"
	tlabel.text = "Not Selected"

func _process(_delta):
	pass

func _on_line_edit_text_submitted(new_text):
	CTT_title = new_text

func _on_attack_button_pressed():
	file_dialog.current_dir = Mitre.downloadpath
	file_dialog.popup_centered()
	
func _on_defend_button_pressed():
	file_dialog2.current_dir = Mitre.downloadpath
	file_dialog2.popup_centered()

func _on_timeline_button_pressed():
	file_dialog3.current_dir = Mitre.downloadpath
	file_dialog3.popup_centered()

# Upload file as opfor_profile.txt
func _on_attack_file_selected(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var save_path = "user://opfor_profile.txt"
		var save_file = FileAccess.open(save_path, FileAccess.WRITE)
		save_file.store_string(content)
		save_file.close()
		attackfile = true
		alabel.text = path.get_file()

# Upload file as defend_profile.txt
func _on_defend_file_selected(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var save_path = "user://defend_profile.txt"
		var save_file = FileAccess.open(save_path, FileAccess.WRITE)
		save_file.store_string(content)
		save_file.close()
		defendfile = true
		dlabel.text = path.get_file()

func _on_timeline_file_selected(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var save_path = "user://mission_timeline.txt"
		var save_file = FileAccess.open(save_path, FileAccess.WRITE)
		save_file.store_string(content)
		save_file.close()
		timelinefile = true
		tlabel.text = path.get_file()

func _on_button_3_pressed():
	Music.mouse_click()
	
	# Force apply text from SpinBox, even if Enter wasn't pressed
	var spinbox = $SpinBox
	var typed_text = spinbox.get_line_edit().text

	if typed_text.is_valid_float():
		var typed_value = float(typed_text)
		if typed_value > 0:
			Mitre.time_limit = int(typed_value * 60)
		else:
			Mitre.time_limit = 5 * 60  # default to 5 minutes if 0 entered
	else:
		Mitre.time_limit = 5 * 60  # fallback if invalid input

	Mitre.import_resources_data(attackfile, defendfile, timelinefile)
	get_tree().change_scene_to_file("res://game_scenes/mission_text/mission_text.tscn")
	hide()


func _on_button_5_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/profiles_screen/profiles_screen.tscn")
	hide()

func _on_spin_box_value_changed(value):
	Mitre.time_limit = int(value*60)

func _on_help_pressed():
	$Window.visible = true

func _on_window_close_requested():
	$Window.visible = false
	
func _on_spin_box_text_submitted(new_text):
	Mitre.time_limit = int(float(new_text) * 60)
	
func _on_spin_box_focus_exited():
	var value = $SpinBox.value
	Mitre.time_limit = int(value * 60)
