extends ParallaxLayer

var progressing = false
var move_time = 1.0
var move_speed = 46
var timer = 0.0
var background_factor = 1.0

func _process(delta):
	if progressing and timer < move_time:
		motion_offset.x -= move_speed * background_factor * delta
		timer += delta
	else:
		progressing = false
		timer = 0

func progress():
	progressing = true
