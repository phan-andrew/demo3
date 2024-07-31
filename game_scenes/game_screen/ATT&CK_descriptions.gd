extends Node2D

var example_dict={}
# Called when the node enters the scene tree for the first time.
func _ready():
	condense()

func get_attack_descrip(index):
	return Mitre.attack_dict[index][2]
	
func condense():
	var descriptions=[]
	var a=0
	while a<205:
		descriptions.append(Mitre.attack_dict[a][2])
