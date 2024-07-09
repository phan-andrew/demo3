extends CharacterBody2D

var move=false
var vel : Vector2=Vector2()
@onready var sprite : Sprite2D =get_node("Pixil-frame-0")

#func wait(seconds: float) -> void:
  #await get_tree().create_timer(seconds).timeout

func _physics_process(delta):
	if Input.is_action_pressed("move_right"):
		move=true
	if move:
		move_and_collide(Vector2(5,0))
		var collision := move_and_collide(Vector2(5,0))
		if collision != null:
			modulate = Color8(40,183,215)
			if Input.is_action_pressed("reset"):
				position.x=0
				position.y=0
				move=false

func _ready():
	pass 
