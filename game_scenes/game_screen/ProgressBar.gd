extends ProgressBar

func _ready():
	print(_load())

func _process(delta):
	pass

func _load():
	var file = FileAccess.open("res://Test_progressbar.txt", FileAccess.READ)
	var content = file.get_as_text()
	return content
