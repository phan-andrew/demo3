extends Node2D

var defend_choice = -1
var attack_choice = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	print(attack_choice)
	print(defend_choice)

func _on_attack_option_item_selected(index):
	attack_choice = index


func _on_defend_option_item_selected(index):
	defend_choice = index
	
