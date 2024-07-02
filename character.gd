extends AnimatableBody2D
var score=0
var speed : int=200
var gravity : int=800
var jumpForce : int= 600
var vel : Vector2=Vector2()
@onready var sprite : Sprite2D =get_node("Icon")


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
func _physics_process(delta):
	vel.x =0 
	if Input.is_action_pressed("move_left"):
		vel.x-=speed
	if Input.is_action_pressed("move_right"):
		vel.x+=speed
	vel=move_and_slide(vel, Vector2.UP)
	
	
	
	
	if vel.x<0:
		sprite.flip_h = true
	elif vel.x>0:
		sprite.flip_h =false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
