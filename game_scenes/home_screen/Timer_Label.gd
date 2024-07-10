extends Label

var initialTime = 600
var startTimer = false
var play = false
var playIcon = preload("res://images/UI images/play_button.png")
var pauseIcon = preload("res://images/UI images/pause_button.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if startTimer && play:
		$Button.icon = pauseIcon
		initialTime -= delta
		var minutes = int(initialTime) / 60
		var seconds = int(initialTime) % 60
		if seconds < 10:
			text = str(minutes) + ":0" + str(seconds)
		else:
			text = str(minutes) + ":" + str(seconds)
	else:
		$Button.icon = playIcon

func _on_button_pressed():
	play = !play
