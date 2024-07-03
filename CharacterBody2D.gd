extends CharacterBody2D

var move=false
var vel : Vector2=Vector2()
@onready var sprite : Sprite2D =get_node("Pixil-frame-0")

func _physics_process(delta):
	if Input.is_action_pressed("move_right"):
		move=true
	if move:
	
		modulate = Color8(40,183,215)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
