extends Node2D

var defend_choice = -1
var attack_choice = -1
var generateACard = false
var generateDCard = false
var attacks = {}
var defends = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	choose_attacks()
	choose_defends()
	add_attack_options()
	add_defend_options()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_attack_option_item_selected(index):
	attack_choice = index
	generateACard = true


func _on_defend_option_item_selected(index):
	defend_choice = int(index)
	generateDCard = true

func choose_attacks():
	var file= FileAccess.open("user://opfor_profile.txt", FileAccess.READ)
	while !file.eof_reached():
		var attack_data_set = Array(file.get_csv_line())
		attacks[attacks.size()] = attack_data_set
	file.close()

func choose_defends():
	var file= FileAccess.open("user://defend_profile.txt", FileAccess.READ)
	while !file.eof_reached():
		var defend_data_set = Array(file.get_csv_line())
		defends[defends.size()] = defend_data_set
	file.close()

func add_attack_options():
	var drop = $attack_option
	var a = 2
	while a<attacks.size():
		drop.add_item(Mitre.attack_dict[int(attacks[a][0])+1][2])
		a+=1
	drop.select(-1)

func add_defend_options():
	var drop = $defend_option
	var a = 2
	while a < defends.size():
		drop.add_item(Mitre.defend_dict[int(defends[a][0])+1][2])
		a+=1
	drop.select(-1)
