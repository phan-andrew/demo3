extends ProgressBar
var percent = 0

func _ready():
	pass

func _process(delta):
	pass

func _load():
	var file = FileAccess.open("res://Test_progressbar.txt", FileAccess.READ)
	var content = file.get_as_text()
	return content

func _on_button_pressed():
	_progress()


func _progress():
	percent = 15
	value = percent
