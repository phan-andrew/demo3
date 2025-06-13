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
func _process(_delta):
	pass

func _on_attack_option_item_selected(index):
	attack_choice = index
	generateACard = true

func _on_defend_option_item_selected(index):
	defend_choice = int(index)
	generateDCard = true

# Add attack options to the attack dropdown
func add_attack_options():
	var drop = $attack_option
	var a = 2
	while a<Mitre.opforprof_dict.size():
		drop.add_item(Mitre.attack_dict[int(Mitre.opforprof_dict[a][0])+1][2])
		a+=1
	drop.select(-1)

# Add defend options to the defend dropdown
func add_defend_options():
	var drop = $defend_option
	var a = 2
	while a < Mitre.d3fendprof_dict.size():
		drop.add_item(Mitre.defend_dict[int(Mitre.d3fendprof_dict[a][0])+1][2])
		a+=1
	drop.select(-1)
