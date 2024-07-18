extends Label

var initialTime = 600
var startTimer = true
var play = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if startTimer && play:
		initialTime -= delta
		var minutes = int(initialTime) / 60
		var seconds = int(initialTime) % 60
		if seconds < 10:
			text = str(minutes) + ":0" + str(seconds)
		else:
			text = str(minutes) + ":" + str(seconds)

