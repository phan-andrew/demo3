extends ParallaxLayer
var progressing = false
var move_time = 2
var timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if progressing && timer < move_time:
		motion_offset.x -= 50 * delta
		timer += delta
	else:
		progressing = false
		timer = 0

func progress():
	progressing = true
