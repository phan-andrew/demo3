extends Node2D

@onready var data = $database_download
@onready var template = $template_download
@onready var filedialog = $FileDialog
@onready var filedialog2 = $FileDialog2
@onready var cont = $Continue
const data_path = "res://data/ATT&CK_database.txt"
const template_path = "res://data/OPFOR_Profile_Template.txt"
@onready var data_download_label = $Label4
@onready var template_download_label = $Label5

# Called when the node enters the scene tree for the first time.
func _ready():
	data.pressed.connect(self._on_download_pressed)
	template.pressed.connect(self._on_template_pressed)
	filedialog.mode = FileDialog.FILE_MODE_SAVE_FILE
	filedialog.file_selected.connect(self._on_file_selected)
	filedialog.filters = ["*.csv"]
	filedialog2.mode = FileDialog.FILE_MODE_SAVE_FILE
	filedialog2.file_selected.connect(self._on_file_2_selected)
	filedialog2.filters = ["*.csv"]
	cont.pressed.connect(self._on_continue_pressed)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_continue_pressed():
	get_tree().change_scene_to_file("res://game_scenes/prompts_screen/starting_prompts.tscn")
	hide ()

func _on_download_pressed():
	filedialog.popup_centered()
	
func _on_template_pressed():
	filedialog2.popup_centered()

func _on_file_selected(path):
	var src_file = FileAccess.open(data_path, FileAccess.ModeFlags.READ)
	if src_file == null:
		data_download_label.text = "Failed to find source"
		return
	
	var data = src_file.get_buffer(src_file.get_length())
	src_file.close()
	var dest_file = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if dest_file == null:
		data_download_label.text = "Failed to open destination file."
		return

	# Write the data to the destination file
	dest_file.store_buffer(data)
	dest_file.close()
	data_download_label.text = "File saved successfully at: " + path

func _on_file_2_selected(path):
	var src_file = FileAccess.open(template_path, FileAccess.ModeFlags.READ)
	if src_file == null:
		template_download_label.text = "Failed to find source"
		return
	
	var data = src_file.get_buffer(src_file.get_length())
	src_file.close()
	var dest_file = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if dest_file == null:
		template_download_label.text = "Failed to open destination file."
		return

	# Write the data to the destination file
	dest_file.store_buffer(data)
	dest_file.close()
	template_download_label.text = "File saved successfully at: " + path
