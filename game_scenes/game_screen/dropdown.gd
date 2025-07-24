extends Node2D

# Selection state
var defend_choice = -1
var attack_choice = -1

# Generation flags (used by game_screen to monitor)
var generateACard = false
var generateDCard = false

# References to card arrays (set by game_screen)
var aCards = []
var dCards = []

func _ready():
	add_attack_options()
	add_defend_options()

func _process(_delta):
	# Handle card generation when selections are made
	if generateACard:
		generate_attack_card()
	
	if generateDCard:
		generate_defense_card()

func set_card_references(attack_cards: Array, defense_cards: Array):
	"""Called by game_screen to provide card references"""
	aCards = attack_cards
	dCards = defense_cards

func _on_attack_option_item_selected(index):
	attack_choice = index
	generateACard = true

func _on_defend_option_item_selected(index):
	defend_choice = int(index)
	generateDCard = true

func generate_attack_card():
	"""Generate attack card based on current selection"""
	if not Mitre or attack_choice < 0:
		generateACard = false
		return
	
	# Find first available attack card slot
	for card in aCards:
		if not card.inPlay:
			var choice_index = attack_choice + 2
			if Mitre.opforprof_dict.has(choice_index):
				var attack_data = Mitre.opforprof_dict[choice_index]
				
				card.setCard(int(attack_data[0]))
				card.setText(int(attack_data[0]))
				card.setTimeValue(int(attack_data[2]))
				card.setCost(int(attack_data[1]))
				card.play()
				
				generateACard = false
				print("Attack card generated: ", Mitre.attack_dict[int(attack_data[0]) + 1][2])  # Attack: index 2 = Name
				break
			else:
				print("Error: Attack choice index not found")
				generateACard = false
				break

func generate_defense_card():
	"""Generate defense card based on current selection"""
	if not Mitre or defend_choice < 0:
		generateDCard = false
		return
	
	# Find first available defense card slot
	for card in dCards:
		if not card.inPlay:
			var choice_index = defend_choice + 2
			if Mitre.d3fendprof_dict.has(choice_index):
				var defense_data = Mitre.d3fendprof_dict[choice_index]
				
				card.setCard(defense_data[0])
				card.setText(defense_data[0])
				card.setMaturity(int(defense_data[1]))
				card.play()
				
				generateDCard = false
				print("Defense card generated: ", Mitre.defend_dict[int(defense_data[0]) + 1][3])  # Defense: index 3 = Name
				break
			else:
				print("Error: Defense choice index not found")
				generateDCard = false
				break

func add_attack_options():
	"""Populate attack dropdown with available options"""
	var drop = $attack_option
	drop.clear()
	
	if not Mitre:
		print("Warning: Mitre not available for attack options")
		return
	
	for i in range(2, Mitre.opforprof_dict.size()):
		var attack_id = int(Mitre.opforprof_dict[i][0])
		if Mitre.attack_dict.has(attack_id + 1):
			var attack_name = Mitre.attack_dict[attack_id + 1][2]  # Attack: index 2 = Name
			drop.add_item(attack_name)
	
	drop.select(-1)

func add_defend_options():
	"""Populate defense dropdown with available options"""
	var drop = $defend_option
	drop.clear()
	
	if not Mitre:
		print("Warning: Mitre not available for defense options")
		return
	
	for i in range(2, Mitre.d3fendprof_dict.size()):
		var defense_id = int(Mitre.d3fendprof_dict[i][0])
		if Mitre.defend_dict.has(defense_id + 1):
			# FIXED: Defense cards have Name at index 3, not index 2
			var defense_name = Mitre.defend_dict[defense_id + 1][3]  # Defense: index 3 = Name
			drop.add_item(defense_name)
	
	drop.select(-1)

func reset_selections():
	"""Reset dropdown selections"""
	$attack_option.select(-1)
	$defend_option.select(-1)
	attack_choice = -1
	defend_choice = -1
	generateACard = false
	generateDCard = false
