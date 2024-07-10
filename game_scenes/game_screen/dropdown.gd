extends Node2D

var defend_choice = -1
var attack_choice = -1
var generateACard = false
var generateDCard = false

# Called when the node enters the scene tree for the first time.
func _ready():
	add_attack_options()
	add_defend_options()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _on_attack_option_item_selected(index):
	attack_choice = index
	generateACard = true


func _on_defend_option_item_selected(index):
	defend_choice = index
	generateDCard = true

func add_attack_options():
	var drop = $attack_option
	var a = 0
	while a<Mitre.attack_dict.size():
		drop.add_item(Mitre.attack_dict[a][1])
		a+=1
	drop.select(-1)
	
func add_defend_options():
	var drop = $defend_option
	var a = 0
	while a < Mitre.defend_dict.size():
		drop.add_item(Mitre.defend_dict[a][0])
		a+=1
	drop.select(-1)
