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
	# Check if all attack slots are already full
	var slots_filled = 0
	for card in aCards:
		if card.inPlay:
			slots_filled += 1
	
	# Only store selection if there's an available slot
	if slots_filled < 3:
		attack_choice = index
		generateACard = true
	else:
		# Reset dropdown if all slots are full
		$attack_option.select(-1)
		print("All attack slots are full! Remove a card first.")

func _on_defend_option_item_selected(index):
	# Check if all defense slots are already full
	var slots_filled = 0
	for card in dCards:
		if card.inPlay:
			slots_filled += 1
	
	# Only store selection if there's an available slot
	if slots_filled < 3:
		defend_choice = int(index)
		generateDCard = true
	else:
		# Reset dropdown if all slots are full
		$defend_option.select(-1)
		print("All defense slots are full! Remove a card first.")

func generate_attack_card():
	"""Generate attack card based on current selection - SIMPLE LOGIC"""
	if not Mitre or attack_choice < 0:
		generateACard = false
		return
	
	# Find first available attack card slot - EXACTLY like original
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
				
				# RESET DROPDOWN SELECTION so you can select the same item again
				$attack_option.select(-1)
				attack_choice = -1
				break
			else:
				print("Error: Attack choice index not found")
				generateACard = false
				break

func generate_defense_card():
	"""Generate defense card based on current selection - SIMPLE LOGIC"""
	if not Mitre or defend_choice < 0:
		generateDCard = false
		return
	
	# Find first available defense card slot - EXACTLY like original
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
				
				# RESET DROPDOWN SELECTION so you can select the same item again
				$defend_option.select(-1)
				defend_choice = -1
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
		var raw = Mitre.d3fendprof_dict[i]
		if typeof(raw) != TYPE_ARRAY or raw.size() < 1:
			print("⚠️ Skipping malformed profile at index", i)
			continue

		var defense_id = int(raw[0])

		if Mitre.defend_dict.has(defense_id + 1):
			var entry = Mitre.defend_dict[defense_id + 1]
			if typeof(entry) == TYPE_ARRAY and entry.size() > 3:
				var defense_name = str(entry[3])
				drop.add_item(defense_name)
			else:
				print("⚠️ Bad defend_dict entry at index", defense_id + 1, "→", entry)
		else:
			print("⚠️ No defend_dict for index", defense_id + 1)

	
	drop.select(-1)

func reset_selections():
	"""Reset dropdown selections"""
	$attack_option.select(-1)
	$defend_option.select(-1)
	attack_choice = -1
	defend_choice = -1
	generateACard = false
	generateDCard = false

func _on_option_button_item_selected(index):
	"""Legacy compatibility function for signal connections"""
	pass
