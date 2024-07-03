extends Node2D

var flipped = false
var hovering = false
var reset_count = 0
var reset = 500

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if hovering:
		reset_count = 0
		if !flipped:
			$AnimationPlayer.play("card_flip")
			flipped = true
	else: 
		reset_count +=1 
	if reset_count > reset && flipped:
		$AnimationPlayer.play_backwards("card_flip")
		flipped = false
		


func _on_area_2d_mouse_shape_entered(shape_idx):
	hovering = true
	

func _on_area_2d_mouse_shape_exited(shape_idx):
	hovering = false
	
