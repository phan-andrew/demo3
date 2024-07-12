extends Label
var scene_title = "0"
var index = 2

func _ready():
	scene_title = Mitre.timeline_dict[index][2]
	text = scene_title

func _process(delta):
	pass

func _on_submit_button_pressed():
	index = index + 1
	scene_title = Mitre.timeline_dict[index][2]
	text = scene_title
