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

var defend_index_map = []  # Maps dropdown index → d3fendprof_dict key

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
		$attack_option.select(0)
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
		$defend_option.select(0)
		print("All defense slots are full! Remove a card first.")

func generate_attack_card():
	"""Generate attack card based on current selection - SIMPLE LOGIC"""
	if not Mitre or attack_choice < 0:
		generateACard = false
		return
	
	# Find first available attack card slot - EXACTLY like original
	for card in aCards:
		if not card.inPlay:
			var choice_index = attack_choice + 1
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
				$attack_option.select(0)
				attack_choice = -1
				break
			else:
				print("Error: Attack choice index not found")
				generateACard = false
				break

func generate_defense_card():
	if not Mitre or defend_choice < 1:
		generateDCard = false
		return

	var index = defend_choice - 1  # because 0 = placeholder
	if index >= defend_index_map.size():
		print("❌ Invalid dropdown index selected: ", index)
		generateDCard = false
		return

	var card_data = defend_index_map[index]
	var card_id = card_data[0]
	var profile_index = card_data[1]

	# Handle two cases: entire database (-1) vs loaded profile (valid index)
	var maturity_level = 3  # reasonable default
	
	if profile_index == -1:
		# Using entire database - no profile loaded
		print("🔵 Using entire database - Card ID: ", card_id, " with default maturity: ", maturity_level)
	else:
		# Using loaded profile
		if not Mitre.d3fendprof_dict.has(profile_index):
			print("❌ Missing profile index: ", profile_index)
			generateDCard = false
			return
		
		var profile = Mitre.d3fendprof_dict[profile_index]
		if profile.size() >= 2:
			maturity_level = int(profile[1])
			print("🔵 Using profile - Card ID: ", card_id, " with maturity: ", maturity_level)
		else:
			print("⚠️ Invalid profile entry, using default maturity")

	# Generate the defense card
	for card in dCards:
		if not card.inPlay:
			card.setCard(card_id)
			card.card_index = card_id
			card.setText(card_id)
			card.setMaturity(maturity_level)
			card.play()

			if Mitre.defend_dict.has(card_id):
				print("✅ Defense card generated: ", Mitre.defend_dict[card_id][3])
			else:
				print("⚠️ Card generated but no defend_dict entry for card_id: ", card_id)

			generateDCard = false
			$defend_option.select(0)
			defend_choice = -2
			break

func add_attack_options():
	"""Populate attack dropdown with available options"""
	var drop = $attack_option
	drop.clear()
	drop.add_item("Select Attack Card")  
	
	if not Mitre:
		print("Warning: Mitre not available for attack options")
		return
	
	for i in range(2, Mitre.opforprof_dict.size()):
		var attack_id = int(Mitre.opforprof_dict[i][0])
		if Mitre.attack_dict.has(attack_id + 1):
			var attack_name = Mitre.attack_dict[attack_id + 1][2]  # Attack: index 2 = Name
			drop.add_item(attack_name)
	
	drop.select(0)

func add_defend_options():
	var drop = $defend_option
	drop.clear()
	defend_index_map.clear()
	drop.add_item("Select Defense Card")  # index 0 = placeholder

	if not Mitre:
		print("⚠️ Mitre not ready")
		return

	# Check if we have a loaded defense profile or should use entire database  
	if Mitre.d3fendprof_dict.size() == 0:
		# No defense profile loaded - show entire defense database
		print("📋 No defense profile - showing entire defense database (", Mitre.defend_dict.size(), " defenses)")
		populate_from_entire_database()
	else:
		# Defense profile loaded - show only selected defenses
		print("📋 Defense profile loaded - showing ", Mitre.d3fendprof_dict.size(), " selected defenses")
		populate_from_defense_profile()

	print("=== DEFENSE DROPDOWN POPULATED ===")
	print("Dropdown items: ", drop.get_item_count() - 1)  # -1 for placeholder

func populate_from_entire_database():
	"""Populate dropdown from entire defense database when no profile is loaded"""
	var drop = $defend_option
	
	# Sort the keys to ensure consistent order
	var sorted_keys = Mitre.defend_dict.keys()
	sorted_keys.sort()
	
	for card_id in sorted_keys:
		var entry = Mitre.defend_dict[card_id]
		if typeof(entry) == TYPE_ARRAY and entry.size() > 3:
			var name = str(entry[3])  # Defense name at index 3
			drop.add_item(name)
			# For entire database, profile_index is -1 (no profile entry)
			defend_index_map.append([card_id, -1])
			print("✅ Added from database: ", name, " (ID: ", card_id, ")")
		else:
			print("⚠️ Invalid database entry for card_id: ", card_id)

func populate_from_defense_profile():
	"""Populate dropdown from user's defense profile"""
	var drop = $defend_option
	var added_card_ids = {}  # Prevent duplicates in profile
	
	for i in range(Mitre.d3fendprof_dict.size()):
		var profile = Mitre.d3fendprof_dict[i]
		if typeof(profile) != TYPE_ARRAY or profile.size() < 2:
			continue

		var card_id = int(profile[0])
		
		# Skip duplicates in profile
		if added_card_ids.has(card_id):
			print("⚠️ Skipping duplicate in profile - Card ID: ", card_id)
			continue
		
		if Mitre.defend_dict.has(card_id):
			var entry = Mitre.defend_dict[card_id]
			if typeof(entry) == TYPE_ARRAY and entry.size() > 3:
				var name = str(entry[3])
				drop.add_item(name)
				defend_index_map.append([card_id, i])
				added_card_ids[card_id] = true
				print("✅ Added from profile: ", name, " (ID: ", card_id, ", Maturity: ", profile[1], ")")
			else:
				print("⚠️ Invalid defense entry for card_id: ", card_id)
		else:
			print("⚠️ Card ID not found in defend_dict: ", card_id)

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
