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
				
				# Find the defense name using robust lookup
				var defense_name = get_defense_name_safe(int(defense_data[0]))
				print("Defense card generated: ", defense_name)
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
	"""Populate defense dropdown with available options - ROBUST VERSION"""
	var drop = $defend_option
	drop.clear()
	
	if not Mitre:
		print("Warning: Mitre not available for defense options")
		return
	
	print("=== DEFENSE LOADING DEBUG ===")
	print("d3fendprof_dict size: ", Mitre.d3fendprof_dict.size())
	print("defend_dict size: ", Mitre.defend_dict.size())
	
	# Debug: Check what keys are actually available in defend_dict
	var available_keys = []
	for i in range(200):  # Check first 200 possible indices
		if Mitre.defend_dict.has(i):
			available_keys.append(i)
		if available_keys.size() >= 10:  # Show first 10 for debug
			break
	print("First 10 defend_dict keys: ", available_keys)
	
	var loaded_count = 0
	var failed_indices = []
	
	# Process mission file entries (starting from row 2 to skip headers)
	for i in range(2, Mitre.d3fendprof_dict.size()):
		if not Mitre.d3fendprof_dict.has(i):
			continue
			
		var defense_row = Mitre.d3fendprof_dict[i]
		if defense_row.size() < 1:
			continue
		
		# Get the defense index from mission file
		var defense_id = int(str(defense_row[0]).strip_edges())
		print("Processing mission defense ID: ", defense_id)
		
		# Try multiple indexing strategies to find the defense
		var defense_name = get_defense_name_safe(defense_id)
		
		if defense_name != "Unknown Defense":
			drop.add_item(defense_name)
			loaded_count += 1
			print("✓ Added: ", defense_name, " (ID: ", defense_id, ")")
		else:
			failed_indices.append(defense_id)
			print("✗ Failed to find defense for ID: ", defense_id)
	
	print("=== RESULTS ===")
	print("Successfully loaded: ", loaded_count, "/", (Mitre.d3fendprof_dict.size() - 2))
	print("Failed indices: ", failed_indices)
	print("Dropdown item count: ", drop.get_item_count())
	
	drop.select(-1)

func get_defense_name_safe(defense_id: int) -> String:
	"""Safely get defense name trying multiple indexing strategies"""
	
	# Strategy 1: Direct index (0-based)
	if Mitre.defend_dict.has(defense_id):
		var entry = Mitre.defend_dict[defense_id]
		if entry.size() > 3:
			print("  Found via direct indexing: ", entry[3])
			return entry[3]  # Name is at index 3
	
	# Strategy 2: Index + 1 (1-based)
	if Mitre.defend_dict.has(defense_id + 1):
		var entry = Mitre.defend_dict[defense_id + 1]
		if entry.size() > 3:
			print("  Found via +1 indexing: ", entry[3])
			return entry[3]
	
	# Strategy 3: Search by ID string (if defend_dict uses string keys)
	var defense_id_str = str(defense_id)
	if Mitre.defend_dict.has(defense_id_str):
		var entry = Mitre.defend_dict[defense_id_str]
		if entry.size() > 3:
			print("  Found via string key: ", entry[3])
			return entry[3]
	
	# Strategy 4: Linear search through defend_dict to find matching index
	for key in Mitre.defend_dict.keys():
		var entry = Mitre.defend_dict[key]
		if entry.size() > 0:
			# Check if first column (Index) matches our defense_id
			if str(entry[0]).strip_edges() == str(defense_id):
				if entry.size() > 3:
					print("  Found via linear search: ", entry[3])
					return entry[3]
	
	# Strategy 5: Check if it's stored as the actual row index in the database
	# (i.e., if database row 5 corresponds to defense index 5)
	var expected_database_keys = [defense_id, defense_id + 1, defense_id - 1]
	for key in expected_database_keys:
		if Mitre.defend_dict.has(key):
			var entry = Mitre.defend_dict[key]
			if entry.size() > 0:
				# Verify this is the right defense by checking the Index column
				if int(str(entry[0]).strip_edges()) == defense_id:
					print("  Found via database row verification: ", entry[3] if entry.size() > 3 else "Unknown Defense")
					return entry[3] if entry.size() > 3 else "Unknown Defense"
	
	print("  No strategy worked for defense ID: ", defense_id)
	return "Unknown Defense"

func reset_selections():
	"""Reset dropdown selections"""
	$attack_option.select(-1)
	$defend_option.select(-1)
	attack_choice = -1
	defend_choice = -1
	generateACard = false
	generateDCard = false
