extends ProgressBar
var percent = 0
var total_segments = 0
var total_time = 0
var current_point = 0
var curent_time = 0

func _ready():
	pass
	# print(_load())

func _process(delta):
	pass

func _load():
	var file = FileAccess.open("res://Test_progressbar2.txt", FileAccess.READ)
	var content = file.get_as_text()
	return content

func _on_button_pressed():
	_progress()

func _progress():
	percent = 15
	value = percent
