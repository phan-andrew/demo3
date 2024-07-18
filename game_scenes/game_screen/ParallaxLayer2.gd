extends ParallaxLayer
var progressing = false
var move_time = 2
var timer = 0
var initial_time
var checkpoint = preload ("res://game_scenes/game_screen/checkpoint.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	initial_time = Mitre.timeline_dict[0][0]
	for row in Mitre.timeline_dict:
		var new_checkpoint = checkpoint.instantiate()
		add_child(new_checkpoint)
		new_checkpoint.position.x = (int(Mitre.timeline_dict[row][0]) - int(initial_time)) * 200
		print(Mitre.timeline_dict[row][0])
		 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if progressing && timer < move_time:
		motion_offset.x -= 200 * delta
		timer += delta
	else:
		progressing = false
		timer = 0

func progress():
	progressing = true
