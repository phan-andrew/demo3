extends Node2D

var defend_choice = -1
var attack_choice = -1
var generateACard = false
var generateDCard = false

# Called when the node enters the scene tree for the first time.
func _ready():
	import_resources_data()
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


var attack_dict={}
var defend_dict={}

func import_resources_data():
	var file= FileAccess.open("res://data/ATT&CK_Names.txt", FileAccess.READ)
	while !file.eof_reached():
		var data_set = Array(file.get_csv_line())
		attack_dict[attack_dict.size()] = data_set
	file.close()
	
	var file2= FileAccess.open("res://data/D3FEND_Names.txt", FileAccess.READ)
	while !file2.eof_reached():
		var data_set2 = Array(file2.get_csv_line())
		defend_dict[defend_dict.size()] = data_set2
	file2.close()
	
func add_attack_options():
	var drop = $attack_option
	var a = 0
	while a<attack_dict.size():
		drop.add_item(attack_dict[a][0])
		a+=1
	drop.select(-1)
	
func add_defend_options():
	var drop = $defend_option
	var a = 0
	while a<defend_dict.size():
		drop.add_item(defend_dict[a][0])
		a+=1
	drop.select(-1)
