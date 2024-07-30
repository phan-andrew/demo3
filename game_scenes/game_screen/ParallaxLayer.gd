extends ParallaxLayer
var progressing = false
var move_time = 2
var move_speed = 200
var timer = 0
var background_factor = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if progressing && timer < move_time:
		motion_offset.x -= move_speed * background_factor * delta
		timer += delta
	else:
		progressing = false
		timer = 0

func progress(speed):
	move_speed = speed
	progressing = true
