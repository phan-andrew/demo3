extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	if Settings.changed_scene == 1:
		$mouse_click.playing = true
		Settings.changed_scene = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
