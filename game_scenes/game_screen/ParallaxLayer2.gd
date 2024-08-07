extends ParallaxLayer
var progressing = false
var move_time = 2
var move_speed = 200
var timer = 0
var initial_time
var initial_x = 500
var checkpoint = preload ("res://game_scenes/game_screen/checkpoint.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	if !Mitre.readtime:
		initial_time = Mitre.timeline_dict[2][0]
		for row in Mitre.timeline_dict:
			if row > 2:
				var new_checkpoint = checkpoint.instantiate()
				add_child(new_checkpoint)
				new_checkpoint.position.x = 500 + (int(Mitre.timeline_dict[row-1][0]) - int(initial_time)) * 50
				new_checkpoint.start()
				new_checkpoint.set_descrip((Mitre.timeline_dict[row-1][1]))
	if Mitre.readtime:
		initial_time=int(Mitre.convert_time(String(Mitre.timeline_dict[2][0])))
		for row in Mitre.timeline_dict:
			if row>2: 
				var new_checkpoint=checkpoint.instantiate()
				add_child(new_checkpoint)
				new_checkpoint.position.x=500+(int(Mitre.convert_time(String(Mitre.timeline_dict[row-1][0])))-int(initial_time))*300
				new_checkpoint.start()
				new_checkpoint.set_descrip((Mitre.timeline_dict[row-1][1]))

func _process(delta):
	if progressing && timer < move_time:
		motion_offset.x -= move_speed * delta
		timer += delta
	else:
		progressing = false
		timer = 0

func progress(speed):
	move_speed = speed
	progressing = true

