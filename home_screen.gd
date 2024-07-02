extends Node2D

var title = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if ($starting_prompts.CTT_title != null && !title):
		$CTT_title.text = $starting_prompts.CTT_title
		title = true
		$starting_prompts.visible = false
