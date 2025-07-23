extends Node2D

var defend_choice = -1
var attack_choice = -1
var generateACard = false
var generateDCard = false

func _ready():
	add_attack_options()
	add_defend_options()

func _process(delta):
	pass

func _on_attack_option_item_selected(index):
	attack_choice = index
	generateACard = true

func _on_defend_option_item_selected(index):
	defend_choice = int(index)
	generateDCard = true

# Add attack options to the attack dropdown
func add_attack_options():
	if not Mitre or Mitre.opforprof_dict.size() <= 2:
		print("Mitre attack data not ready")
		return
		
	var drop = $attack_option
	var a = 2
	while a < Mitre.opforprof_dict.size():
		if Mitre.opforprof_dict.has(a) and Mitre.opforprof_dict[a].size() > 0:
			var dict_index = int(Mitre.opforprof_dict[a][0]) + 1
			if Mitre.attack_dict.has(dict_index) and Mitre.attack_dict[dict_index].size() > 2:
				drop.add_item(Mitre.attack_dict[dict_index][2])  # Index 2 = Name for attacks
		a += 1
	drop.select(-1)

# Add defend options to the defend dropdown  
func add_defend_options():
	if not Mitre or Mitre.d3fendprof_dict.size() <= 2:
		print("Mitre defense data not ready")
		return
		
	var drop = $defend_option
	var a = 2
	while a < Mitre.d3fendprof_dict.size():
		if Mitre.d3fendprof_dict.has(a) and Mitre.d3fendprof_dict[a].size() > 0:
			var dict_index = int(Mitre.d3fendprof_dict[a][0]) + 1
			if Mitre.defend_dict.has(dict_index) and Mitre.defend_dict[dict_index].size() > 3:
				drop.add_item(Mitre.defend_dict[dict_index][3])  # Index 3 = Name for defenses
		a += 1
	drop.select(-1)
