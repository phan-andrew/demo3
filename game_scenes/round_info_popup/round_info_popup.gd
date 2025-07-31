extends Panel

signal round_info_closed()

@onready var title_label = $VBoxContainer/TitleLabel
@onready var desc_label = $VBoxContainer/DescLabel
@onready var subsystems_label = $VBoxContainer/SubSystems
@onready var close_button = $VBoxContainer/CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)

func set_round_info(round_num: int, header: String, description: String, subsystems: String):
	title_label.text = "Round %d - %s" % [round_num , header]
	desc_label.text = description
	subsystems_label.text = "Subsystems offline: " + (subsystems if subsystems != "None" else "None")

func _on_close_pressed():
	emit_signal("round_info_closed")
	queue_free()
