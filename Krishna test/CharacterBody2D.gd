extends CharacterBody2D

var move=true
var vectorx=7
var vectory=7
var vel : Vector2=Vector2()
@onready var sprite : Sprite2D =get_node("Pixil-frame-0")

#func wait(seconds: float) -> void:
  #await get_tree().create_timer(seconds).timeout

func _physics_process(delta):
	
	if move:
		move_and_collide(Vector2(vectorx,vectory))
		var collision := move_and_collide(Vector2(vectorx,vectory))
		if collision != null:
			var rng=RandomNumberGenerator.new()
			modulate = Color8(40,183,215)
			if rng.randi_range(0,1)==0:
				vectorx=-vectorx
			if rng.randi_range(0,1)==0:
				vectory=-vectory
			if rng.randi_range(0,6)==2:
				vectorx+=1
				vectory+=1
			
			

func _ready():
	pass 


	
func _on_mouse_entered():
	get_tree().change_scene_to_file("res://game_scenes/help_screen/help_screen.tscn")
