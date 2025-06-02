extends Node2D

@onready var attack_data = $attack_database_download
@onready var opfor_template = $opfor_template_download
@onready var defend_data = $defend_database_download
@onready var defense_template = $defense_template_download
@onready var timeline_template = $timeline_template_download
@onready var cont = $Continue

@onready var filedialog = $FileDialog
@onready var filedialog2 = $FileDialog2
@onready var filedialog3 = $FileDialog3
@onready var filedialog4 = $FileDialog4
@onready var filedialog5 = $FileDialog5

const attack_data_path = "res://data/ATT&CK_database.txt"
const defend_data_path = "res://data/D3fend_database.txt"
const opfor_template_path = "res://data/OPFOR_Template.txt"
const defend_template_path = "res://data/Defense_Template.txt"
const timeline_template_path = "res://data/Timeline_Template.txt"

@onready var attack_data_download_label = $Label4
@onready var opfor_template_download_label = $Label5
@onready var defend_data_download_label = $Label6
@onready var defense_template_download_label = $Label7
@onready var timeline_template_download_label = $Label8

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.texture = load(Settings.textured[Settings.theme])
	attack_data.pressed.connect(self._on_attack_download_pressed)
	filedialog.mode = FileDialog.FILE_MODE_SAVE_FILE
	filedialog.file_selected.connect(self._on_file_selected)
	filedialog.filters = ["*.csv"]
	
	opfor_template.pressed.connect(self._on_opfor_template_pressed)
	filedialog2.mode = FileDialog.FILE_MODE_SAVE_FILE
	filedialog2.file_selected.connect(self._on_file_2_selected)
	filedialog2.filters = ["*.csv"]
	
	defend_data.pressed.connect(self._on_defend_data_pressed)
	filedialog3.mode = FileDialog.FILE_MODE_SAVE_FILE
	filedialog3.file_selected.connect(self._on_file_3_selected)
	filedialog3.filters = ["*.csv"]
	
	defense_template.pressed.connect(self._on_defense_template_pressed)
	filedialog4.mode = FileDialog.FILE_MODE_SAVE_FILE
	filedialog4.file_selected.connect(self._on_file_4_selected)
	filedialog4.filters = ["*.csv"]
	
	timeline_template.pressed.connect(self._on_timeline_template_pressed)
	filedialog5.mode = FileDialog.FILE_MODE_SAVE_FILE
	filedialog5.file_selected.connect(self._on_file_5_selected)
	filedialog5.filters = ["*.csv"]
	
	cont.pressed.connect(self._on_continue_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_continue_pressed():
	Music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/prompts_screen/starting_prompts.tscn")
	hide ()

func _on_attack_download_pressed():
	filedialog.current_dir = Mitre.downloadpath
	filedialog.current_file = "attack_database"
	filedialog.popup_centered()

func _on_opfor_template_pressed():
	filedialog2.current_dir = Mitre.downloadpath
	filedialog2.current_file = "opfor_template"
	filedialog2.popup_centered()

func _on_defend_data_pressed():
	filedialog3.current_dir = Mitre.downloadpath
	filedialog3.current_file = "defend_database"
	filedialog3.popup_centered()

func _on_defense_template_pressed():
	filedialog4.current_dir = Mitre.downloadpath
	filedialog4.current_file = "defense_template"
	filedialog4.popup_centered()

func _on_timeline_template_pressed():
	filedialog5.current_dir = Mitre.downloadpath
	filedialog5.current_file = "timeline_template"
	filedialog5.popup_centered()

func _on_file_selected(path):
	var src_file = FileAccess.open(attack_data_path, FileAccess.ModeFlags.READ)
	if src_file == null:
		attack_data_download_label.text = "Failed to find source"
		return
	
	var data = src_file.get_buffer(src_file.get_length())
	src_file.close()
	var dest_file = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if dest_file == null:
		attack_data_download_label.text = "Failed to open destination file."
		return

	# Write the data to the destination file
	dest_file.store_buffer(data)
	dest_file.close()
	attack_data_download_label.text = "File saved successfully at: " + path

func _on_file_2_selected(path):
	var src_file = FileAccess.open(opfor_template_path, FileAccess.ModeFlags.READ)
	if src_file == null:
		opfor_template_download_label.text = "Failed to find source"
		return
	
	var data = src_file.get_buffer(src_file.get_length())
	src_file.close()
	var dest_file = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if dest_file == null:
		opfor_template_download_label.text = "Failed to open destination file."
		return

	# Write the data to the destination file
	dest_file.store_buffer(data)
	dest_file.close()
	opfor_template_download_label.text = "File saved successfully at: " + path

func _on_file_3_selected(path):
	var src_file = FileAccess.open(defend_data_path, FileAccess.ModeFlags.READ)
	if src_file == null:
		defend_data_download_label.text = "Failed to find source"
		return
	
	var data = src_file.get_buffer(src_file.get_length())
	src_file.close()
	var dest_file = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if dest_file == null:
		defend_data_download_label.text = "Failed to open destination file."
		return

	# Write the data to the destination file
	dest_file.store_buffer(data)
	dest_file.close()
	defend_data_download_label.text = "File saved successfully at: " + path

func _on_file_4_selected(path):
	var src_file = FileAccess.open(defend_template_path, FileAccess.ModeFlags.READ)
	if src_file == null:
		defense_template_download_label.text = "Failed to find source"
		return
	
	var data = src_file.get_buffer(src_file.get_length())
	src_file.close()
	var dest_file = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if dest_file == null:
		defense_template_download_label.text = "Failed to open destination file."
		return

	# Write the data to the destination file
	dest_file.store_buffer(data)
	dest_file.close()
	defense_template_download_label.text = "File saved successfully at: " + path

func _on_file_5_selected(path):
	var src_file = FileAccess.open(timeline_template_path, FileAccess.ModeFlags.READ)
	if src_file == null:
		timeline_template_download_label.text = "Failed to find source"
		return
	
	var data = src_file.get_buffer(src_file.get_length())
	src_file.close()
	var dest_file = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if dest_file == null:
		timeline_template_download_label.text = "Failed to open destination file."
		return

	# Write the data to the destination file
	dest_file.store_buffer(data)
	dest_file.close()
	timeline_template_download_label.text = "File saved successfully at: " + path
	

func _on_button_pressed():
	Music.mouse_click()
	if !Mitre.preloadedmission:
		get_tree().change_scene_to_file("res://game_scenes/mission_input_screen/mission_inputs.tscn")
		hide()
	else:
		get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
		hide ()

func _on_help_pressed():
	$Window.visible = true

func _on_window_close_requested():
	$Window.visible = false
