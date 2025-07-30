extends Node

# Attack chain progression system
enum AttackStep {
	EMPTY,  # No foothold
	IA,     # Initial Access established 
	PEP,    # Privilege Escalation/Persistence established
	E_E     # Execution/Exfiltration achieved - WIN CONDITION
}

# Position tracking - 3 independent positions that can progress
var attack_positions = [
	{"state": AttackStep.EMPTY, "name": "Position 1"},
	{"state": AttackStep.EMPTY, "name": "Position 2"}, 
	{"state": AttackStep.EMPTY, "name": "Position 3"}
]

# Current round data
var current_attack_cards = []
var current_defense_cards = []
var round_number = 1

# Attack success rate table with individual calculations
var attack_success_table = {
	"c1t1": {"time": 1, "cost": 1, "rate": 5, "likelihood": 90},
	"c1t2": {"time": 1, "cost": 2, "rate": 5, "likelihood": 85},
	"c1t3": {"time": 1, "cost": 3, "rate": 4, "likelihood": 75},
	"c1t4": {"time": 1, "cost": 4, "rate": 3, "likelihood": 65},
	"c1t5": {"time": 1, "cost": 5, "rate": 3, "likelihood": 60},
	"c2t1": {"time": 2, "cost": 1, "rate": 5, "likelihood": 85},
	"c2t2": {"time": 2, "cost": 2, "rate": 4, "likelihood": 75},
	"c2t3": {"time": 2, "cost": 3, "rate": 4, "likelihood": 70},
	"c2t4": {"time": 2, "cost": 4, "rate": 3, "likelihood": 60},
	"c2t5": {"time": 2, "cost": 5, "rate": 3, "likelihood": 55},
	"c3t1": {"time": 3, "cost": 1, "rate": 4, "likelihood": 70},
	"c3t2": {"time": 3, "cost": 2, "rate": 4, "likelihood": 65},
	"c3t3": {"time": 3, "cost": 3, "rate": 3, "likelihood": 55},
	"c3t4": {"time": 3, "cost": 4, "rate": 2, "likelihood": 45},
	"c3t5": {"time": 3, "cost": 5, "rate": 2, "likelihood": 40},
	"c4t1": {"time": 4, "cost": 1, "rate": 3, "likelihood": 55},
	"c4t2": {"time": 4, "cost": 2, "rate": 3, "likelihood": 50},
	"c4t3": {"time": 4, "cost": 3, "rate": 2, "likelihood": 40},
	"c4t4": {"time": 4, "cost": 4, "rate": 2, "likelihood": 35},
	"c4t5": {"time": 4, "cost": 5, "rate": 1, "likelihood": 25},
	"c5t1": {"time": 5, "cost": 1, "rate": 3, "likelihood": 50},
	"c5t2": {"time": 5, "cost": 2, "rate": 3, "likelihood": 45},
	"c5t3": {"time": 5, "cost": 3, "rate": 2, "likelihood": 35},
	"c5t4": {"time": 5, "cost": 4, "rate": 1, "likelihood": 25},
	"c5t5": {"time": 5, "cost": 5, "rate": 1, "likelihood": 20}
}

# Game state tracking for data export
var game_history = []
var current_round_data = {}

# Signals
signal dice_roll_completed_signal
signal attack_chain_victory  # Red team wins - any position reaches E/E
signal timeline_victory      # Blue team wins - time/timeline ends
signal discussion_time_needed(results: Array)  # Pause for discussion

func _ready():
	reset_attack_chains()

func reset_attack_chains():
	"""Reset all attack positions to EMPTY state"""
	for i in range(3):
		attack_positions[i]["state"] = AttackStep.EMPTY
	round_number = 1
	game_history.clear()
	current_round_data.clear()

func capture_current_cards(attack_cards: Array, defense_cards: Array):
	"""Capture current round cards with individual calculations"""
	current_attack_cards.clear()
	current_defense_cards.clear()
	
	print("=== ROUND ", round_number, " CARD CAPTURE ===")
	
	# Debug: Run comprehensive card debugging
	run_comprehensive_card_debug(attack_cards, defense_cards)
	
	# Capture attack cards with their individual properties
	for i in range(min(attack_cards.size(), 3)):
		var card = attack_cards[i]
		if card and card.inPlay == true and card.card_index != -1:
			var card_data = {
				"card": card,
				"position_index": i,
				"cost": card.getCostValue() if card.has_method("getCostValue") else 1,
				"time": card.getTimeValue() if card.has_method("getTimeValue") else 1,
				"name": get_attack_name(card),
				"card_type": get_attack_type(card)  # IA, PEP, or E/E type
			}
			current_attack_cards.append(card_data)
			print("Attack ", i + 1, ": ", card_data.name, " (Type: ", card_data.card_type, ", Cost: ", card_data.cost, ", Time: ", card_data.time, ")")
	
	# Capture defense cards with 1:1 mapping
	for i in range(min(defense_cards.size(), 3)):
		var card = defense_cards[i]
		if card and card.inPlay == true and card.card_index != -1:
			var card_data = {
				"card": card,
				"position_index": i,
				"maturity": card.getMaturityValue() if card.has_method("getMaturityValue") else 1,
				"name": get_defense_name(card),
				"is_eviction": is_eviction_card(card)  # Check if it's an eviction card
			}
			current_defense_cards.append(card_data)
			print("Defense ", i + 1, ": ", card_data.name, " (Maturity: ", card_data.maturity, ", Eviction: ", card_data.is_eviction, ")")
		else:
			current_defense_cards.append(null)
	
	# Store current round start state
	current_round_data = {
		"round_number": round_number,
		"starting_positions": get_position_states_snapshot(),
		"attack_cards": current_attack_cards.duplicate(),
		"defense_cards": current_defense_cards.duplicate(),
		"timestamp": Time.get_time_string_from_system()
	}

func get_card_pairing_info() -> Array:
	"""Get individual card pairing information with proper calculations"""
	var pairings = []
	
	print("=== CREATING INDIVIDUAL CARD PAIRINGS ===")
	
	# Create pairing for each attack card individually
	for attack_data in current_attack_cards:
		var position_index = attack_data.position_index
		var defense_data = null
		if position_index < current_defense_cards.size():
			defense_data = current_defense_cards[position_index]
		
		var pairing = create_individual_card_pairing(attack_data, defense_data, position_index)
		pairings.append(pairing)
		
		print("Pairing ", position_index + 1, ":")
		print("  Attack: ", pairing.attack_name, " (", pairing.intended_step, ")")
		print("  Defense: ", pairing.defense_name)
		print("  Individual Success Rate: ", pairing.success_percentage, "% -> Threshold: ", pairing.dice_threshold)
		print("  Valid Play: ", pairing.is_valid_play, " | Auto Success: ", pairing.auto_success)
	
	return pairings

func create_individual_card_pairing(attack_data: Dictionary, defense_data, position_index: int) -> Dictionary:
	"""Create pairing with individual card calculations"""
	var current_position_state = attack_positions[position_index]["state"]
	var intended_step = determine_intended_step(attack_data.card_type, current_position_state)
	
	var pairing = {
		"attack_index": position_index,
		"attack_name": attack_data.name,
		"defense_name": "No Defense" if defense_data == null else defense_data.name,
		"individual_cost": attack_data.cost,
		"individual_time": attack_data.time,
		"current_position_state": get_step_name(current_position_state),
		"intended_step": intended_step,
		"is_valid_play": is_valid_attack_play(attack_data.card_type, current_position_state),
		"auto_success": false,
		"success_percentage": 0.0,
		"rounded_percentage": 0,
		"dice_threshold": 10
	}
	
	# Check if this is a valid play
	if not pairing.is_valid_play:
		pairing.success_percentage = 0.0
		pairing.rounded_percentage = 0
		pairing.dice_threshold = 10
		pairing.invalid_play = true
		print("INVALID PLAY: Cannot play ", attack_data.card_type, " when position is at ", get_step_name(current_position_state))
		return pairing
	
	# Calculate individual success rate
	var base_rate = calculate_individual_attack_success_rate(attack_data.cost, attack_data.time)
	
	if defense_data == null:
		# No defense - auto success
		pairing.auto_success = true
		pairing.success_percentage = 100.0
		pairing.rounded_percentage = 100
		pairing.dice_threshold = 10
	else:
		# Apply defense modifiers
		var defense_modifier = calculate_defense_modifier(defense_data.maturity)
		
		# Special case: Eviction cards
		if defense_data.is_eviction and current_position_state != AttackStep.EMPTY:
			defense_modifier += 0.2  # 20% bonus against established positions
		
		var final_rate = base_rate * (1.0 - defense_modifier)
		pairing.success_percentage = final_rate * 100.0
		pairing.rounded_percentage = round_to_nearest_ten(pairing.success_percentage)
		pairing.dice_threshold = pairing.rounded_percentage / 10
	
	return pairing

func determine_intended_step(card_type: String, current_state: AttackStep) -> String:
	"""Determine what step this card is trying to achieve"""
	match card_type:
		"IA":
			return "IA"
		"PEP": 
			if current_state >= AttackStep.IA:
				return "PEP"
			else:
				return "INVALID - No IA foothold"
		"E/E":
			if current_state >= AttackStep.PEP:
				return "E/E"
			else:
				return "INVALID - No PEP foothold"
		_:
			return "Unknown"

func is_valid_attack_play(card_type: String, current_state: AttackStep) -> bool:
	"""Check if an attack card can be played in the current position state"""
	match card_type:
		"IA":
			return true  # IA can always be played (establish or re-establish foothold)
		"PEP":
			return current_state >= AttackStep.IA  # Need IA foothold first
		"E/E":
			return current_state >= AttackStep.PEP  # Need PEP foothold first
		_:
			return false

func calculate_individual_attack_success_rate(cost: int, time: int) -> float:
	"""Calculate success rate for individual card"""
	var clamped_cost = clamp(cost, 1, 5)
	var clamped_time = clamp(int(time / 24), 1, 5)  # Convert minutes to 1-5 scale
	
	var key = "c" + str(clamped_cost) + "t" + str(clamped_time)
	var attack_data = attack_success_table.get(key, {"likelihood": 50})
	var base_rate = attack_data.likelihood / 100.0
	
	print("Individual calculation - Cost: ", clamped_cost, " Time: ", clamped_time, " -> ", base_rate * 100, "%")
	return base_rate

func calculate_defense_modifier(maturity: int) -> float:
	"""Calculate defense effectiveness modifier (0.0 to 0.4)"""
	return (maturity - 1.0) / 4.0 * 0.4

func round_to_nearest_ten(percentage: float) -> int:
	"""Round percentage to nearest 10 for dice threshold"""
	return int(round(percentage / 10.0) * 10)

func record_dice_results(results: Array):
	"""Record dice results and process connected attack chain logic"""
	print("=== PROCESSING DICE RESULTS ===")
	
	var round_results = []
	
	# Process each individual result
	for result in results:
		var position_index = result.attack_index
		var success = result.success
		var attack_data = current_attack_cards[position_index] if position_index < current_attack_cards.size() else null
		
		if not attack_data:
			continue
			
		var result_data = {
			"position_index": position_index,
			"attack_name": result.attack_name,
			"defense_name": result.defense_name,
			"success": success,
			"roll_result": result.roll_result,
			"auto_success": result.get("auto_success", false),
			"invalid_play": result.get("invalid_play", false),
			"previous_state": get_step_name(attack_positions[position_index]["state"]),
			"intended_step": attack_data.card_type if attack_data else "Unknown"
		}
		
		# Apply results to connected attack chain
		if success and not result.get("invalid_play", false):
			var previous_state = attack_positions[position_index]["state"]
			advance_position_state(position_index, attack_data.card_type)
			result_data["new_state"] = get_step_name(attack_positions[position_index]["state"])
			print("Position ", position_index + 1, " advanced from ", result_data.previous_state, " to ", result_data.new_state)
		else:
			result_data["new_state"] = result_data.previous_state
			if result.get("invalid_play", false):
				print("Position ", position_index + 1, " - INVALID PLAY: ", result.attack_name)
			else:
				print("Position ", position_index + 1, " - FAILED: ", result.attack_name)
		
		round_results.append(result_data)
	
	# Process defense evictions
	process_defense_evictions()
	
	# Save round data to history
	current_round_data["results"] = round_results
	current_round_data["ending_positions"] = get_position_states_snapshot()
	game_history.append(current_round_data.duplicate())
	
	# Check win conditions
	if check_red_team_victory():
		print("RED TEAM VICTORY - Position reached E/E!")
		emit_signal("attack_chain_victory")
		return
	
	# Emit discussion time signal
	emit_signal("discussion_time_needed", round_results)

func advance_position_state(position_index: int, card_type: String):
	"""Advance a position state based on successful attack"""
	var current_state = attack_positions[position_index]["state"]
	
	match card_type:
		"IA":
			attack_positions[position_index]["state"] = AttackStep.IA
		"PEP":
			if current_state >= AttackStep.IA:
				attack_positions[position_index]["state"] = AttackStep.PEP
		"E/E":
			if current_state >= AttackStep.PEP:
				attack_positions[position_index]["state"] = AttackStep.E_E

func process_defense_evictions():
	"""Process defense eviction cards that can reset positions"""
	for i in range(current_defense_cards.size()):
		var defense_data = current_defense_cards[i]
		if defense_data != null and defense_data.is_eviction:
			# Check if this defense successfully evicted
			# This would be determined by the specific eviction card logic
			# For now, we'll implement basic eviction on high maturity
			if defense_data.maturity >= 4 and attack_positions[i]["state"] != AttackStep.EMPTY:
				print("EVICTION: Position ", i + 1, " evicted by ", defense_data.name)
				attack_positions[i]["state"] = AttackStep.EMPTY

func check_red_team_victory() -> bool:
	"""Check if red team has won (any position reached E/E)"""
	for position in attack_positions:
		if position["state"] == AttackStep.E_E:
			return true
	return false

func get_step_name(step: AttackStep) -> String:
	"""Get readable name for attack step"""
	match step:
		AttackStep.EMPTY:
			return "EMPTY"
		AttackStep.IA:
			return "IA"
		AttackStep.PEP:
			return "PEP"
		AttackStep.E_E:
			return "E/E"
		_:
			return "Unknown"

func get_position_states_snapshot() -> Array:
	"""Get current position states for single progress bar tracking"""
	var states = []
	for i in range(3):
		states.append({
			"position": i,  # 0-indexed for compatibility
			"state": get_step_name(attack_positions[i]["state"])
		})
	return states

func get_most_advanced_position_state() -> String:
	"""Get the most advanced position state for single progress bar display"""
	var max_state = AttackStep.EMPTY
	
	for position in attack_positions:
		if position["state"] > max_state:
			max_state = position["state"]
	
	return get_step_name(max_state)

func get_most_advanced_position_progress() -> int:
	"""Get progress level (0-3) for single progress bar image selection"""
	var max_state = AttackStep.EMPTY
	
	for position in attack_positions:
		if position["state"] > max_state:
			max_state = position["state"]
	
	# Return progress level that maps directly to image indices
	match max_state:
		AttackStep.EMPTY:
			return 0  # 0.png - Empty
		AttackStep.IA:
			return 1  # 1.png - IA filled
		AttackStep.PEP:
			return 2  # 2.png - PEP filled
		AttackStep.E_E:
			return 3  # 3.png - E/E filled (victory)
		_:
			return 0

# Helper functions for card identification
func get_attack_name(attack_card) -> String:
	"""Get attack card name safely"""
	if not attack_card:
		return "Unknown Attack"
	
	var card_index = attack_card.card_index
	if has_node("/root/Mitre"):
		var mitre = get_node("/root/Mitre")
		if mitre.attack_dict.has(card_index + 1):
			return mitre.attack_dict[card_index + 1][2]  # Attack: index 2 = Name
	return "Attack Card"

func get_defense_name(defense_card) -> String:
	"""Get defense card name safely"""
	if not defense_card:
		return "No Defense"
	
	var card_index = defense_card.card_index
	if has_node("/root/Mitre"):
		var mitre = get_node("/root/Mitre")
		if mitre.defend_dict.has(card_index + 1):
			return mitre.defend_dict[card_index + 1][3]  # Defense: index 3 = Name
	return "Defense Card"

func get_attack_type(attack_card) -> String:
	"""Determine attack card type (IA, PEP, E/E) based on MITRE classification"""
	if not attack_card:
		return "IA"
	
	var card_index = attack_card.card_index
	if has_node("/root/Mitre"):
		var mitre = get_node("/root/Mitre")
		if mitre.attack_dict.has(card_index + 1):
			# CSV structure: Index,ID,Name,Description,Path,Classification,Type
			# So classification is at index 5
			var attack_entry = mitre.attack_dict[card_index + 1]
			if attack_entry.size() > 5:
				var classification = int(attack_entry[5])
				match classification:
					1:
						return "IA"  # Initial Access
					2:
						return "PEP"  # Privilege Escalation/Persistence
					3:
						return "E/E"  # Impact/Exfiltration
					4:
						return "PEP"  # Persistence (treat as PEP)
					_:
						return "IA"  # Default to IA
			else:
				print("Warning: Attack entry missing classification field for card_index: ", card_index)
				return "IA"
	
	print("Warning: Could not determine attack type for card_index: ", card_index)
	return "IA"  # Default

func is_eviction_card(defense_card) -> bool:
	"""Check if defense card is an eviction card"""
	if not defense_card:
		return false
	
	var card_name = get_defense_name(defense_card)
	# Define eviction cards by name - you can expand this list
	var eviction_cards = [
		"Process Termination",
		"File Removal", 
		"Credential Revoking",
		"System Shutdown",
		"Account Access Removal"
	]
	
	return card_name in eviction_cards

# Data export functions
func export_game_data_to_csv() -> String:
	"""Export complete game data to CSV format"""
	var csv_data = ""
	
	# Headers
	var headers = [
		"Round", "Timestamp", "Position_1_Start", "Position_2_Start", "Position_3_Start",
		"Attack_1", "Attack_1_Cost", "Attack_1_Time", "Attack_1_Type", "Attack_1_Valid",
		"Attack_2", "Attack_2_Cost", "Attack_2_Time", "Attack_2_Type", "Attack_2_Valid", 
		"Attack_3", "Attack_3_Cost", "Attack_3_Time", "Attack_3_Type", "Attack_3_Valid",
		"Defense_1", "Defense_1_Maturity", "Defense_1_Eviction",
		"Defense_2", "Defense_2_Maturity", "Defense_2_Eviction",
		"Defense_3", "Defense_3_Maturity", "Defense_3_Eviction",
		"Result_1", "Roll_1", "Success_1", "New_State_1",
		"Result_2", "Roll_2", "Success_2", "New_State_2", 
		"Result_3", "Roll_3", "Success_3", "New_State_3",
		"Position_1_End", "Position_2_End", "Position_3_End",
		"Red_Victory", "Round_Notes"
	]
	
	csv_data += ",".join(headers) + "\n"
	
	# Data rows
	for round_data in game_history:
		var row = []
		row.append(str(round_data.round_number))
		row.append(round_data.timestamp)
		
		# Starting positions
		for pos_data in round_data.starting_positions:
			row.append(pos_data.state)
		
		# Attack card data
		for i in range(3):
			if i < round_data.attack_cards.size():
				var attack = round_data.attack_cards[i]
				row.append(attack.name)
				row.append(str(attack.cost))
				row.append(str(attack.time))
				row.append(attack.card_type)
				row.append("Valid")  # You can add validation check here
			else:
				row.append_array(["---", "---", "---", "---", "---"])
		
		# Defense card data
		for i in range(3):
			if i < round_data.defense_cards.size() and round_data.defense_cards[i] != null:
				var defense = round_data.defense_cards[i]
				row.append(defense.name)
				row.append(str(defense.maturity))
				row.append("Yes" if defense.is_eviction else "No")
			else:
				row.append_array(["---", "---", "---"])
		
		# Results data
		for i in range(3):
			if i < round_data.results.size():
				var result = round_data.results[i]
				row.append("Success" if result.success else "Failure")
				row.append(str(result.roll_result) if result.has("roll_result") else "AUTO")
				row.append("Yes" if result.success else "No")
				row.append(result.new_state)
			else:
				row.append_array(["---", "---", "---", "---"])
		
		# Ending positions
		for pos_data in round_data.ending_positions:
			row.append(pos_data.state)
		
		# Victory check
		var victory = false
		for pos_data in round_data.ending_positions:
			if pos_data.state == "E/E":
				victory = true
				break
		row.append("Yes" if victory else "No")
		row.append("Round " + str(round_data.round_number) + " completed")
		
		csv_data += ",".join(row) + "\n"
	
	return csv_data

func prepare_next_round():
	"""Prepare for next round"""
	round_number += 1
	current_attack_cards.clear()
	current_defense_cards.clear()
	current_round_data.clear()

# Debug functions
func debug_show_game_state():
	"""Debug function to show current game state"""
	print("=== CURRENT GAME STATE ===")
	print("Round: ", round_number)
	for i in range(3):
		print("Position ", i + 1, ": ", get_step_name(attack_positions[i]["state"]))
	print("Most Advanced: ", get_most_advanced_position_state(), " (Progress Level: ", get_most_advanced_position_progress(), ")")
	print("Active attack cards: ", current_attack_cards.size())
	print("Active defense cards: ", current_defense_cards.size())
	print("=== END GAME STATE ===")

func debug_show_attack_table():
	"""Debug function to show attack success table"""
	print("=== ATTACK SUCCESS RATE TABLE ===")
	for key in attack_success_table.keys():
		var entry = attack_success_table[key]
		print(key, " -> Cost:", entry.cost, " Time:", entry.time, " Likelihood:", entry.likelihood, "%")
	print("=== END TABLE ===")

# ===== DEBUG FUNCTIONS =====

func debug_print_attack_card_structure(card_index: int):
	"""Print the structure of an attack card for debugging"""
	print("=== DEBUG ATTACK CARD STRUCTURE ===")
	print("Card Index: ", card_index)
	
	if has_node("/root/Mitre"):
		var mitre = get_node("/root/Mitre")
		var dict_key = card_index + 1
		print("Dictionary Key: ", dict_key)
		
		if mitre.attack_dict.has(dict_key):
			var attack_entry = mitre.attack_dict[dict_key]
			print("Entry Size: ", attack_entry.size())
			print("Full Entry: ", attack_entry)
			
			# Print each field with its index
			for i in range(attack_entry.size()):
				print("  Index ", i, ": ", attack_entry[i])
			
			# Expected structure verification
			if attack_entry.size() >= 6:
				print("--- PARSED FIELDS ---")
				print("Index (0): ", attack_entry[0])
				print("ID (1): ", attack_entry[1]) 
				print("Name (2): ", attack_entry[2])
				print("Description (3): ", attack_entry[3])
				print("Path (4): ", attack_entry[4])
				print("Classification (5): ", attack_entry[5])
				if attack_entry.size() > 6:
					print("Type (6): ", attack_entry[6])
				
				# Classification mapping
				var classification = int(attack_entry[5])
				var type_name = ""
				match classification:
					1: type_name = "IA (Initial Access)"
					2: type_name = "PEP (Privilege Escalation/Persistence)"
					3: type_name = "E/E (Impact/Exfiltration)"  
					4: type_name = "PEP (Persistence)"
					_: type_name = "Unknown (" + str(classification) + ")"
				print("Mapped Type: ", type_name)
			else:
				print("ERROR: Entry too short - expected at least 6 fields")
		else:
			print("ERROR: Dictionary key not found")
	else:
		print("ERROR: Mitre node not found")
	print("=== END DEBUG ===")

func debug_print_defense_card_structure(card_index: int):
	"""Print the structure of a defense card for debugging"""
	print("=== DEBUG DEFENSE CARD STRUCTURE ===")
	print("Card Index: ", card_index)
	
	if has_node("/root/Mitre"):
		var mitre = get_node("/root/Mitre")
		var dict_key = card_index + 1
		print("Dictionary Key: ", dict_key)
		
		if mitre.defend_dict.has(dict_key):
			var defense_entry = mitre.defend_dict[dict_key]
			print("Entry Size: ", defense_entry.size())
			print("Full Entry: ", defense_entry)
			
			# Print each field with its index
			for i in range(defense_entry.size()):
				print("  Index ", i, ": ", defense_entry[i])
			
			# Expected structure verification
			if defense_entry.size() >= 6:
				print("--- PARSED FIELDS ---")
				print("Index (0): ", defense_entry[0])
				print("ID (1): ", defense_entry[1])
				print("Category (2): ", defense_entry[2])
				print("Name (3): ", defense_entry[3])
				print("Description (4): ", defense_entry[4])
				print("Path (5): ", defense_entry[5])
			else:
				print("ERROR: Entry too short - expected at least 6 fields")
		else:
			print("ERROR: Dictionary key not found")
	else:
		print("ERROR: Mitre node not found")
	print("=== END DEBUG ===")

func debug_all_active_cards(attack_cards: Array, defense_cards: Array):
	"""Debug all currently active cards"""
	print("=== DEBUG ALL ACTIVE CARDS ===")
	
	print("Attack Cards:")
	for i in range(attack_cards.size()):
		var card = attack_cards[i]
		if card and card.inPlay and card.card_index != -1:
			print("  Position ", i + 1, ":")
			debug_print_attack_card_structure(card.card_index)
		else:
			print("  Position ", i + 1, ": No active card")
	
	print("Defense Cards:")
	for i in range(defense_cards.size()):
		var card = defense_cards[i]
		if card and card.inPlay and card.card_index != -1:
			print("  Position ", i + 1, ":")
			debug_print_defense_card_structure(card.card_index)
		else:
			print("  Position ", i + 1, ": No active card")
	
	print("=== END DEBUG ALL CARDS ===")

func test_attack_classification_mapping():
	"""Test the attack classification mapping with known cards"""
	print("=== TESTING ATTACK CLASSIFICATION ===")
	
	if not has_node("/root/Mitre"):
		print("ERROR: Mitre node not found")
		return
	
	var mitre = get_node("/root/Mitre")
	var test_cases = []
	
	# Test first few cards to verify mapping
	for i in range(1, min(11, mitre.attack_dict.size() + 1)):  # 1-indexed
		if mitre.attack_dict.has(i):
			var entry = mitre.attack_dict[i]
			if entry.size() >= 6:
				test_cases.append({
					"index": i - 1,  # Convert back to 0-based for card_index
					"name": entry[2],
					"classification": int(entry[5])
				})
	
	print("Testing ", test_cases.size(), " attack cards:")
	for test_case in test_cases:
		var mock_card = {"card_index": test_case.index}
		var determined_type = get_attack_type(mock_card)
		
		var expected_type = ""
		match test_case.classification:
			1: expected_type = "IA"
			2: expected_type = "PEP"
			3: expected_type = "E/E"
			4: expected_type = "PEP"
			_: expected_type = "IA"
		
		var status = "✓" if determined_type == expected_type else "✗"
		print("  ", status, " ", test_case.name, " (Class: ", test_case.classification, ") -> Expected: ", expected_type, ", Got: ", determined_type)
	
	print("=== END CLASSIFICATION TEST ===")

func debug_card_pairing_calculations():
	"""Debug the card pairing calculations"""
	print("=== DEBUG CARD PAIRING CALCULATIONS ===")
	
	var pairings = get_card_pairing_info()
	
	for i in range(pairings.size()):
		var pairing = pairings[i]
		print("Pairing ", i + 1, ":")
		print("  Attack: ", pairing.attack_name)
		print("  Type: ", pairing.get("card_type", "Unknown"))
		print("  Position State: ", pairing.current_position_state)
		print("  Intended Step: ", pairing.intended_step)
		print("  Valid Play: ", pairing.is_valid_play)
		print("  Individual Cost: ", pairing.individual_cost)
		print("  Individual Time: ", pairing.individual_time)
		print("  Success Rate: ", pairing.success_percentage, "%")
		print("  Dice Threshold: ", pairing.dice_threshold)
		print("  Auto Success: ", pairing.auto_success)
		if pairing.has("invalid_play"):
			print("  Invalid Play: ", pairing.invalid_play)
		print("  Defense: ", pairing.defense_name)
		print("")
	
	print("=== END PAIRING DEBUG ===")

# Call this function to run comprehensive debugging
func run_comprehensive_card_debug(attack_cards: Array, defense_cards: Array):
	"""Run all debugging functions"""
	print("\n" + "=".repeat(50))
	print("COMPREHENSIVE CARD DEBUG SESSION")
	print("=".repeat(50))
	
	test_attack_classification_mapping()
	debug_all_active_cards(attack_cards, defense_cards)
	
	if current_attack_cards.size() > 0 or current_defense_cards.size() > 0:
		debug_card_pairing_calculations()
	
	print("=".repeat(50))
	print("END COMPREHENSIVE DEBUG")
	print("=".repeat(50) + "\n")

# ===== ENHANCED CSV EXPORT FUNCTIONS =====

# Enhanced detailed export with console-like information
func export_detailed_game_data_to_csv() -> String:
	"""Export comprehensive game data with detailed analysis information"""
	var csv_data = ""
	
	# Main game summary headers
	var summary_headers = [
		"Game_Summary", "Total_Rounds", "Game_Duration", "Red_Team_Victory", 
		"Final_Position_1", "Final_Position_2", "Final_Position_3", 
		"Most_Advanced_State", "Total_Attacks_Attempted", "Total_Attacks_Successful",
		"Total_Defenses_Active", "Average_Attack_Cost", "Average_Attack_Time",
		"Average_Defense_Maturity", "Notes"
	]
	
	csv_data += "=== GAME SUMMARY ===\n"
	csv_data += ",".join(summary_headers) + "\n"
	csv_data += generate_game_summary_row() + "\n\n"
	
	# Detailed round-by-round analysis
	csv_data += "=== DETAILED ROUND ANALYSIS ===\n"
	var detailed_headers = [
		"Round", "Timestamp", "Round_Phase", "Position_1_State", "Position_2_State", "Position_3_State",
		"Attack_1_Name", "Attack_1_Type", "Attack_1_Cost", "Attack_1_Time", "Attack_1_Valid_Play",
		"Attack_2_Name", "Attack_2_Type", "Attack_2_Cost", "Attack_2_Time", "Attack_2_Valid_Play",
		"Attack_3_Name", "Attack_3_Type", "Attack_3_Cost", "Attack_3_Time", "Attack_3_Valid_Play",
		"Defense_1_Name", "Defense_1_Maturity", "Defense_1_Category", "Defense_1_Eviction",
		"Defense_2_Name", "Defense_2_Maturity", "Defense_2_Category", "Defense_2_Eviction",
		"Defense_3_Name", "Defense_3_Maturity", "Defense_3_Category", "Defense_3_Eviction",
		"Total_Attack_Cost", "Total_Attack_Time", "Average_Defense_Maturity",
		"Calculation_Method", "Base_Success_Rate", "Defense_Modifier", "Final_Success_Rate",
		"Round_Outcome", "Positions_Advanced", "Round_Notes"
	]
	
	csv_data += ",".join(detailed_headers) + "\n"
	
	# Add round data
	for round_data in game_history:
		csv_data += generate_detailed_round_row(round_data) + "\n"
	
	csv_data += "\n=== INDIVIDUAL ATTACK RESULTS ===\n"
	var attack_headers = [
		"Round", "Attack_Position", "Attack_Name", "Attack_Type", "Individual_Cost", "Individual_Time",
		"Defense_Name", "Defense_Maturity", "Target_Position_State", "Intended_Step",
		"Individual_Success_Rate", "Dice_Threshold", "Roll_Result", "Roll_Method",
		"Attack_Success", "Reason", "Position_Advanced_From", "Position_Advanced_To",
		"Attack_Chain_Progress", "Console_Output_Equivalent"
	]
	
	csv_data += ",".join(attack_headers) + "\n"
	
	# Add individual attack data
	for round_data in game_history:
		if round_data.has("results"):
			for result in round_data.results:
				csv_data += generate_individual_attack_row(round_data, result) + "\n"
	
	csv_data += "\n=== POSITION STATE TRACKING ===\n"
	var position_headers = [
		"Round", "Event_Type", "Position_1_Before", "Position_1_After", "Position_1_Change",
		"Position_2_Before", "Position_2_After", "Position_2_Change",
		"Position_3_Before", "Position_3_After", "Position_3_Change",
		"Most_Advanced_Before", "Most_Advanced_After", "Progress_Level_Change",
		"Red_Team_Threat_Level", "Analysis_Notes"
	]
	
	csv_data += ",".join(position_headers) + "\n"
	
	# Add position tracking data
	for round_data in game_history:
		csv_data += generate_position_tracking_row(round_data) + "\n"
	
	csv_data += "\n=== CALCULATION DETAILS ===\n"
	var calc_headers = [
		"Round", "Attack_Position", "Base_Cost", "Base_Time", "Lookup_Key", 
		"Base_Success_Rate", "Defense_Present", "Defense_Maturity", "Defense_Modifier",
		"Eviction_Bonus", "Final_Success_Rate", "Rounded_Percentage", "Dice_Threshold",
		"Calculation_Formula", "Console_Debug_Output"
	]
	
	csv_data += ",".join(calc_headers) + "\n"
	
	# Add calculation details
	for round_data in game_history:
		if round_data.has("attack_cards"):
			for i in range(round_data.attack_cards.size()):
				csv_data += generate_calculation_detail_row(round_data, i) + "\n"
	
	return csv_data

func generate_game_summary_row() -> String:
	"""Generate overall game summary row"""
	var total_rounds = game_history.size()
	var red_victory = false
	var final_positions = ["EMPTY", "EMPTY", "EMPTY"]
	var most_advanced = "EMPTY"
	var total_attacks = 0
	var successful_attacks = 0
	var total_defenses = 0
	var total_cost = 0
	var total_time = 0
	var total_maturity = 0
	var defense_count = 0
	
	# Analyze final state and statistics
	if game_history.size() > 0:
		var final_round = game_history[game_history.size() - 1]
		if final_round.has("ending_positions"):
			for i in range(min(3, final_round.ending_positions.size())):
				final_positions[i] = final_round.ending_positions[i].state
				if final_round.ending_positions[i].state == "E/E":
					red_victory = true
				# Track most advanced
				if is_more_advanced(final_round.ending_positions[i].state, most_advanced):
					most_advanced = final_round.ending_positions[i].state
	
	# Calculate statistics across all rounds
	for round_data in game_history:
		if round_data.has("attack_cards"):
			total_attacks += round_data.attack_cards.size()
			for attack in round_data.attack_cards:
				total_cost += attack.get("cost", 0)
				total_time += attack.get("time", 0)
		
		if round_data.has("defense_cards"):
			for defense in round_data.defense_cards:
				if defense != null:
					total_defenses += 1
					total_maturity += defense.get("maturity", 0)
					defense_count += 1
		
		if round_data.has("results"):
			for result in round_data.results:
				if result.get("success", false):
					successful_attacks += 1
	
	var avg_cost = total_cost / float(max(total_attacks, 1))
	var avg_time = total_time / float(max(total_attacks, 1))
	var avg_maturity = total_maturity / float(max(defense_count, 1))
	
	var game_duration = Time.get_time_string_from_system()  # This could be improved with actual duration tracking
	
	var notes = "Game completed with " + str(total_rounds) + " rounds. "
	notes += "Red team " + ("won" if red_victory else "lost") + ". "
	notes += "Success rate: " + str(int((successful_attacks / float(max(total_attacks, 1))) * 100)) + "%"
	
	var row = [
		"SEACAT_Connected_Attack_Chain_Game",
		str(total_rounds),
		game_duration,
		"Yes" if red_victory else "No",
		final_positions[0],
		final_positions[1], 
		final_positions[2],
		most_advanced,
		str(total_attacks),
		str(successful_attacks),
		str(total_defenses),
		"%.2f" % avg_cost,
		"%.2f" % avg_time,
		"%.2f" % avg_maturity,
		notes
	]
	
	return ",".join(row)

func generate_detailed_round_row(round_data: Dictionary) -> String:
	"""Generate detailed round analysis row"""
	var row = []
	
	# Basic round info
	row.append(str(round_data.get("round_number", 0)))
	row.append(round_data.get("timestamp", ""))
	row.append("Round_Complete")
	
	# Position states (start of round)
	var starting_positions = round_data.get("starting_positions", [])
	for i in range(3):
		if i < starting_positions.size():
			row.append(starting_positions[i].state)
		else:
			row.append("EMPTY")
	
	# Attack card details
	var attack_cards = round_data.get("attack_cards", [])
	for i in range(3):
		if i < attack_cards.size():
			var attack = attack_cards[i]
			row.append(attack.get("name", "---"))
			row.append(attack.get("card_type", "---"))
			row.append(str(attack.get("cost", "---")))
			row.append(str(attack.get("time", "---")))
			row.append("Valid")  # Could add validation logic here
		else:
			row.append_array(["---", "---", "---", "---", "---"])
	
	# Defense card details
	var defense_cards = round_data.get("defense_cards", [])
	for i in range(3):
		if i < defense_cards.size() and defense_cards[i] != null:
			var defense = defense_cards[i]
			row.append(defense.get("name", "---"))
			row.append(str(defense.get("maturity", "---")))
			row.append("Category_" + str(i + 1))  # Could add actual category lookup
			row.append("Yes" if defense.get("is_eviction", false) else "No")
		else:
			row.append_array(["---", "---", "---", "---"])
	
	# Round calculations
	var total_cost = 0
	var total_time = 0
	var total_maturity = 0
	var defense_count = 0
	
	for attack in attack_cards:
		total_cost += attack.get("cost", 0)
		total_time += attack.get("time", 0)
	
	for defense in defense_cards:
		if defense != null:
			total_maturity += defense.get("maturity", 0)
			defense_count += 1
	
	row.append(str(total_cost))
	row.append(str(total_time))
	row.append("%.2f" % (total_maturity / float(max(defense_count, 1))))
	
	# Analysis
	row.append("Individual_Card_Calculations")
	row.append("Base_Attack_Success_Table")
	row.append("Defense_Maturity_Modifier")
	row.append("Individual_Thresholds")
	
	# Round outcome
	var results = round_data.get("results", [])
	var successes = 0
	for result in results:
		if result.get("success", false):
			successes += 1
	
	row.append(str(successes) + "_of_" + str(results.size()) + "_succeeded")
	row.append(str(successes))
	
	var notes = "Round " + str(round_data.get("round_number", 0)) + " completed. "
	notes += str(successes) + "/" + str(results.size()) + " attacks succeeded. "
	notes += "Total cost: $" + str(total_cost) + ", Total time: " + str(total_time) + " min."
	row.append(notes)
	
	return ",".join(row)

func generate_individual_attack_row(round_data: Dictionary, result: Dictionary) -> String:
	"""Generate individual attack result row with console-like output"""
	var row = []
	
	row.append(str(round_data.get("round_number", 0)))
	row.append(str(result.get("position_index", 0) + 1))
	row.append(result.get("attack_name", "Unknown"))
	row.append(result.get("intended_step", "Unknown"))
	row.append(str(result.get("individual_cost", 0)))
	row.append(str(result.get("individual_time", 0)))
	row.append(result.get("defense_name", "No Defense"))
	row.append(str(result.get("defense_maturity", 0)))
	row.append(result.get("previous_state", "EMPTY"))
	row.append(result.get("intended_step", "Unknown"))
	row.append(str(result.get("success_percentage", 0)) + "%")
	row.append(str(result.get("dice_threshold", 10)))
	row.append(str(result.get("roll_result", 0)))
	
	# Roll method
	if result.get("auto_success", false):
		row.append("Auto_Success")
	elif result.get("invalid_play", false):
		row.append("Invalid_Play")
	else:
		row.append("Dice_Roll")
	
	row.append("Yes" if result.get("success", false) else "No")
	
	# Reason for success/failure
	var reason = ""
	if result.get("auto_success", false):
		reason = "No_Defense_Present"
	elif result.get("invalid_play", false):
		reason = "Invalid_Attack_Chain_Sequence"
	elif result.get("success", false):
		reason = "Roll_" + str(result.get("roll_result", 0)) + "_≤_" + str(result.get("dice_threshold", 10))
	else:
		reason = "Roll_" + str(result.get("roll_result", 0)) + "_>_" + str(result.get("dice_threshold", 10))
	row.append(reason)
	
	row.append(result.get("previous_state", "EMPTY"))
	row.append(result.get("new_state", "EMPTY"))
	
	# Attack chain progress
	var progress = get_attack_chain_progress_description(result.get("previous_state", "EMPTY"), result.get("new_state", "EMPTY"))
	row.append(progress)
	
	# Console output equivalent
	var console_output = "Attack " + str(result.get("position_index", 0) + 1) + ": " + result.get("attack_name", "Unknown")
	console_output += " | Cost: $" + str(result.get("individual_cost", 0)) + ", Time: " + str(result.get("individual_time", 0)) + " min"
	console_output += " | " + result.get("previous_state", "EMPTY") + " → " + result.get("new_state", "EMPTY")
	console_output += " | " + ("SUCCESS" if result.get("success", false) else "FAILURE")
	if not result.get("auto_success", false) and not result.get("invalid_play", false):
		console_output += " (Rolled " + str(result.get("roll_result", 0)) + "/" + str(result.get("dice_threshold", 10)) + ")"
	row.append("\"" + console_output + "\"")
	
	return ",".join(row)

func generate_position_tracking_row(round_data: Dictionary) -> String:
	"""Generate position state tracking row"""
	var row = []
	
	row.append(str(round_data.get("round_number", 0)))
	row.append("Round_Resolution")
	
	var starting_positions = round_data.get("starting_positions", [])
	var ending_positions = round_data.get("ending_positions", [])
	
	var start_most_advanced = "EMPTY"
	var end_most_advanced = "EMPTY"
	
	# Position changes
	for i in range(3):
		var start_state = "EMPTY"
		var end_state = "EMPTY"
		
		if i < starting_positions.size():
			start_state = starting_positions[i].state
		if i < ending_positions.size():
			end_state = ending_positions[i].state
		
		row.append(start_state)
		row.append(end_state)
		
		# Change description
		if start_state == end_state:
			row.append("No_Change")
		else:
			row.append(start_state + "_to_" + end_state)
		
		# Track most advanced
		if is_more_advanced(start_state, start_most_advanced):
			start_most_advanced = start_state
		if is_more_advanced(end_state, end_most_advanced):
			end_most_advanced = end_state
	
	row.append(start_most_advanced)
	row.append(end_most_advanced)
	
	# Progress level change
	var start_level = get_progress_level(start_most_advanced)
	var end_level = get_progress_level(end_most_advanced)
	row.append(str(end_level - start_level))
	
	# Threat level analysis
	var threat_level = "Low"
	if end_most_advanced == "E/E":
		threat_level = "VICTORY_RED_TEAM"
	elif end_most_advanced == "PEP":
		threat_level = "Critical"
	elif end_most_advanced == "IA":
		threat_level = "Moderate"
	row.append(threat_level)
	
	var analysis = "Round " + str(round_data.get("round_number", 0)) + " changed most advanced position from " + start_most_advanced + " to " + end_most_advanced
	row.append(analysis)
	
	return ",".join(row)

func generate_calculation_detail_row(round_data: Dictionary, attack_index: int) -> String:
	"""Generate detailed calculation breakdown row"""
	var row = []
	var attack_cards = round_data.get("attack_cards", [])
	var defense_cards = round_data.get("defense_cards", [])
	
	if attack_index >= attack_cards.size():
		# Return empty row if no attack - fix the array multiplication issue
		var empty_row = []
		for i in range(15):
			empty_row.append("---")
		return ",".join(empty_row)
	
	var attack = attack_cards[attack_index]
	var defense = null
	if attack_index < defense_cards.size():
		defense = defense_cards[attack_index]
	
	row.append(str(round_data.get("round_number", 0)))
	row.append(str(attack_index + 1))
	row.append(str(attack.get("cost", 1)))
	row.append(str(attack.get("time", 1)))
	
	# Lookup key calculation
	var clamped_cost = clamp(attack.get("cost", 1), 1, 5)
	var clamped_time = clamp(int(attack.get("time", 1) / 24), 1, 5)
	var lookup_key = "c" + str(clamped_cost) + "t" + str(clamped_time)
	row.append(lookup_key)
	
	# Get base success rate - ensure it's a number, not array
	var base_rate = 50  # Default
	if attack_success_table.has(lookup_key):
		var table_entry = attack_success_table[lookup_key]
		base_rate = int(table_entry.likelihood)  # Ensure it's an int
	row.append(str(base_rate) + "%")
	
	row.append("Yes" if defense != null else "No")
	row.append(str(defense.get("maturity", 0)) if defense else "0")
	
	# Calculate modifiers - ensure all values are numbers
	var defense_modifier = 0.0
	if defense:
		var maturity_val = int(defense.get("maturity", 1))
		defense_modifier = (maturity_val - 1.0) / 4.0 * 0.4
	row.append("%.3f" % defense_modifier)
	
	var eviction_bonus = 0.0
	if defense and defense.get("is_eviction", false):
		eviction_bonus = 0.2  # 20% bonus for eviction cards
	row.append("%.3f" % eviction_bonus)
	
	# Final calculations - ensure base_rate is a number
	var final_rate = float(base_rate) * (1.0 - defense_modifier - eviction_bonus)
	var rounded_percentage = int(round(final_rate / 10.0) * 10)
	var dice_threshold = rounded_percentage / 10
	
	row.append("%.2f" % final_rate + "%")
	row.append(str(rounded_percentage) + "%")
	row.append(str(dice_threshold))
	
	# Formula
	var formula = str(base_rate) + "% × (1 - " + "%.3f" % defense_modifier
	if eviction_bonus > 0:
		formula += " - " + "%.3f" % eviction_bonus
	formula += ") = " + "%.2f" % final_rate + "%"
	row.append("\"" + formula + "\"")
	
	# Console debug equivalent
	var debug_output = "Individual calculation - Cost: " + str(clamped_cost) + " Time: " + str(clamped_time) + " -> " + str(base_rate) + "% base"
	if defense:
		debug_output += ", Defense modifier: -" + "%.1f" % (defense_modifier * 100) + "%"
	debug_output += " = " + "%.1f" % final_rate + "% final"
	row.append("\"" + debug_output + "\"")
	
	return ",".join(row)

# Helper functions for analysis
func is_more_advanced(state1: String, state2: String) -> bool:
	"""Check if state1 is more advanced than state2"""
	var levels = {"EMPTY": 0, "IA": 1, "PEP": 2, "E/E": 3}
	return levels.get(state1, 0) > levels.get(state2, 0)

func get_progress_level(state: String) -> int:
	"""Get numeric progress level for state"""
	var levels = {"EMPTY": 0, "IA": 1, "PEP": 2, "E/E": 3}
	return levels.get(state, 0)

func get_attack_chain_progress_description(from_state: String, to_state: String) -> String:
	"""Get description of attack chain progression"""
	if from_state == to_state:
		return "No_Progress"
	elif to_state == "IA" and from_state == "EMPTY":
		return "Initial_Access_Established"
	elif to_state == "PEP" and from_state == "IA":
		return "Privilege_Escalation_Achieved" 
	elif to_state == "E/E" and from_state == "PEP":
		return "Execution_Exfiltration_SUCCESS"
	elif to_state == "EMPTY":
		return "Position_Evicted"
	else:
		return from_state + "_to_" + to_state

# Function to save enhanced export
func save_enhanced_game_export():
	"""Save the enhanced detailed game export"""
	var enhanced_data = export_detailed_game_data_to_csv()
	var enhanced_path = OS.get_user_data_dir() + "/seacat_enhanced_detailed_export.csv"
	var file = FileAccess.open(enhanced_path, FileAccess.WRITE)
	if file:
		file.store_string(enhanced_data)
		file.close()
		print("Enhanced detailed game data exported to: ", enhanced_path)
		return enhanced_path
	else:
		print("Failed to save enhanced export")
		return ""
