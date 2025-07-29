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

# Missing defense data for immediate fix
var missing_defense_names = {
	46: "File Integrity Monitoring",
	67: "Multi-factor Authentication", 
	68: "Network Traffic Analysis",
	71: "Operating System Monitoring",
	85: "Restore Database",
	86: "Restore Disk Image", 
	87: "Restore File",
	88: "Restore Network Access",
	89: "Restore Software",
	90: "Restore User Account Access",
	99: "Software Update",
	102: "Strong Password Policy",
	104: "System Configuration Permissions", 
	107: "URL Analysis",
	109: "User Account Permissions",
	111: "Web Session Activity Analysis"
}

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
	"""Populate defense dropdown with available options - WITH MISSING DEFENSE FIX"""
	var drop = $defend_option
	drop.clear()
	
	if not Mitre:
		print("Warning: Mitre not available for defense options")
		return
	
	print("=== DEFENSE LOADING (WITH FIX) ===")
	var loaded_count = 0
	var fixed_count = 0
	
	# Process mission file entries (starting from row 2 to skip headers)
	for i in range(2, Mitre.d3fendprof_dict.size()):
		if not Mitre.d3fendprof_dict.has(i):
			continue
			
		var defense_row = Mitre.d3fendprof_dict[i]
		if defense_row.size() < 1:
			continue
		
		# Get the defense index from mission file
		var defense_id = int(str(defense_row[0]).strip_edges())
		var defense_name = ""
		
		# Try to get from defend_dict first
		if Mitre.defend_dict.has(defense_id):
			var entry = Mitre.defend_dict[defense_id]
			if entry.size() > 3:
				defense_name = entry[3]
				loaded_count += 1
		
		# If not found, use our missing defense fix
		elif missing_defense_names.has(defense_id):
			defense_name = missing_defense_names[defense_id]
			fixed_count += 1
		
		# Add to dropdown if we have a name
		if defense_name != "":
			drop.add_item(defense_name)
			print("✓ Added: ", defense_name, " (ID: ", defense_id, ")")
		else:
			print("✗ Still missing: ID ", defense_id)
	
	print("=== RESULTS ===")
	print("Loaded from database: ", loaded_count)
	print("Fixed with fallback: ", fixed_count)
	print("Total in dropdown: ", drop.get_item_count())
	print("Expected: 30")
	
	drop.select(-1)

func get_defense_name_safe(defense_id: int) -> String:
	"""Safely get defense name with missing defense fix"""
	
	# Try defend_dict first
	if Mitre.defend_dict.has(defense_id):
		var entry = Mitre.defend_dict[defense_id]
		if entry.size() > 3:
			return entry[3]
	
	# Use missing defense fallback
	if missing_defense_names.has(defense_id):
		return missing_defense_names[defense_id]
	
	return "Unknown Defense"

func reset_selections():
	"""Reset dropdown selections"""
	$attack_option.select(-1)
	$defend_option.select(-1)
	attack_choice = -1
	defend_choice = -1
	generateACard = false
	generateDCard = false
