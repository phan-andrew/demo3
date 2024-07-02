extends AnimatableBody2D
var schore: int=0 
var speed: int=200
var vel : Vector2=Vector2()
@onready var sprite : AnimatableBody2D =get_node("Card")
# Called when the node enters the scene tree for the first time.
func _physics_process(delta):
	vel.x =0 
	if Input.is_action_just_pressed("move_right"):
		vel.x=1000
	move_and_slide()
	
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
