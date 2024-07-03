extends Label

var initialTime = 600
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	initialTime -= delta
	var minutes = int(initialTime) / 60
	var seconds = int(initialTime) % 60
	text = str(minutes) + ":" + str(seconds)
