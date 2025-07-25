extends Node

# Enhanced GameData - Connected Attack Chain Progression System
# Each position progresses through IA → PEP → E/E independently but connectedly

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
			print("Attack ", i + 1, ": ", card_data.name, " (Cost: ", card_data.cost, ", Time: ", card_data.time, ")")
	
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
			print("Defense ", i + 1, ": ", card_data.name, " (Maturity: ", card_data.maturity, ")")
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
	"""Get current position states for tracking"""
	var states = []
	for i in range(3):
		states.append({
			"position": i + 1,
			"state": get_step_name(attack_positions[i]["state"])
		})
	return states

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
		return "Unknown"
	
	var card_index = attack_card.card_index
	if has_node("/root/Mitre"):
		var mitre = get_node("/root/Mitre")
		if mitre.attack_dict.has(card_index + 1):
			var classification = mitre.attack_dict[card_index + 1].get(5, 1)  # Assuming index 5 is classification
			match int(classification):
				1:
					return "IA"  # Initial Access
				2:
					return "PEP"  # Privilege Escalation/Persistence
				3:
					return "E/E"  # Execution/Exfiltration
				_:
					return "IA"  # Default to IA
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
