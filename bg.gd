extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Settings.theme == 0:
		$bg.modulate = Color(0.0, 0.25, 0.5)
	if Settings.theme == 1:
		$bg.modulate = Color(0.146, 0.372, 0.959)
	if Settings.theme == 2:
		$bg.modulate = Color(0.552, 0.415, 0.161)
