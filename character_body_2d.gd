extends CharacterBody2D

var score=0
var speed : int=5000
var vel : Vector2=Vector2()
@onready var sprite : Sprite2D =get_node("Icon")

func _process(delta):
	if input_event:
		position += Vector2(5, 0)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

	
