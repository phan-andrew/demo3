extends Node

# Attack chain progression system
enum AttackStep {
	EMPTY,  # No foothold
	IA,     # Initial Access established 
	PEP,    # Privilege Escalation/Persistence established
	E_E     # Execution/Exfiltration achieved - WIN CONDITION
}

# Defense types enum
enum DefenseType {
	PROTECT = 1,  # Works against IA attacks
	DETECT = 2,   # Works against PEP attacks
	RESPOND = 3,  # Works against E/E attacks
	RECOVER = 4   # Wildcard - works against any attack, resets to EMPTY on win
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
				"defense_type": get_defense_type(card),  # PROTECT, DETECT, RESPOND, RECOVER
				"is_eviction": is_eviction_card(card)  # Keep for backwards compatibility
			}
			current_defense_cards.append(card_data)
			print("Defense ", i + 1, ": ", card_data.name, " (Type: ", get_defense_type_name(card_data.defense_type), ", Maturity: ", card_data.maturity, ")")
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
		print("  Defense: ", pairing.defense_name, " (", pairing.defense_match_status, ")")
		print("  Individual Success Rate: ", pairing.success_percentage, "% -> Threshold: ", pairing.dice_threshold)
		print("  Valid Play: ", pairing.is_valid_play, " | Auto Success: ", pairing.auto_success)
		print("  Defense Effective: ", pairing.defense_effective)
	
	return pairings

func create_individual_card_pairing(attack_data: Dictionary, defense_data, position_index: int) -> Dictionary:
	"""Create pairing with individual card calculations and defense type matching"""
	var current_position_state = attack_positions[position_index]["state"]
	var intended_step = determine_intended_step(attack_data.card_type, current_position_state)
	var is_valid_attack = is_valid_attack_play(attack_data.card_type, current_position_state)
	
	var pairing = {
		"attack_index": position_index,
		"attack_name": attack_data.name,
		"defense_name": "No Defense" if defense_data == null else defense_data.name,
		"individual_cost": attack_data.cost,
		"individual_time": attack_data.time,
		"current_position_state": get_step_name(current_position_state),
		"intended_step": intended_step,
		"is_valid_play": is_valid_attack,
		"auto_success": false,
		"auto_failure": false,
		"success_percentage": 0.0,
		"rounded_percentage": 0,
		"dice_threshold": 10,
		"defense_effective": false,
		"defense_match_status": "No Defense",
		"is_wildcard_defense": false
	}
	
	# RULE 1: Red team invalid plays = Auto-fail
	if not is_valid_attack:
		pairing.success_percentage = 0.0
		pairing.rounded_percentage = 0
		pairing.dice_threshold = 10
		pairing.invalid_play = true
		pairing.auto_failure = true
		pairing.defense_match_status = "Red Invalid Play - Auto Fail"
		print("RED INVALID PLAY: Cannot play ", attack_data.card_type, " when position is at ", get_step_name(current_position_state), " - AUTO FAIL")
		return pairing
	
	# Red team play is valid, now check defense
	if defense_data == null:
		# No defense - auto success for red
		pairing.auto_success = true
		pairing.success_percentage = 100.0
		pairing.rounded_percentage = 100
		pairing.dice_threshold = 10
		pairing.defense_match_status = "No Defense - Auto Success"
		print("NO DEFENSE: Red team auto success")
	else:
		# Check defense type matching
		var defense_effective = is_defense_effective_against_attack(defense_data.defense_type, attack_data.card_type)
		pairing.defense_effective = defense_effective
		pairing.is_wildcard_defense = (defense_data.defense_type == DefenseType.RECOVER)
		
		if defense_effective:
			# Defense is effective - normal dice roll
			if defense_data.defense_type == DefenseType.RECOVER:
				pairing.defense_match_status = "Wildcard Match (Recover) - Dice Roll"
			else:
				pairing.defense_match_status = "Type Match - Dice Roll"
			
			# Calculate individual success rate and apply defense modifiers
			var base_rate = calculate_individual_attack_success_rate(attack_data.cost, attack_data.time)
			var defense_modifier = calculate_defense_modifier(defense_data.maturity)
			var final_rate = base_rate * (1.0 - defense_modifier)
			pairing.success_percentage = final_rate * 100.0
			pairing.rounded_percentage = round_to_nearest_ten(pairing.success_percentage)
			pairing.dice_threshold = pairing.rounded_percentage / 10
			print("EFFECTIVE DEFENSE: ", get_defense_type_name(defense_data.defense_type), " vs ", attack_data.card_type, " - Normal dice roll")
		else:
			# RULE 2: Blue team incompatible defense = Red team auto-win
			pairing.defense_match_status = "Incompatible Defense - Red Auto Win"
			pairing.auto_success = true
			pairing.success_percentage = 100.0
			pairing.rounded_percentage = 100
			pairing.dice_threshold = 10
			print("INCOMPATIBLE DEFENSE: ", get_defense_type_name(defense_data.defense_type), " vs ", attack_data.card_type, " - RED AUTO WIN")
	
	print("Final Analysis: ", pairing.defense_match_status, " | Auto Success: ", pairing.auto_success, " | Auto Failure: ", pairing.auto_failure)
	
	return pairing

func is_defense_effective_against_attack(defense_type: int, attack_type: String) -> bool:
	"""Check if defense type is effective against attack type"""
	match defense_type:
		DefenseType.PROTECT:
			return attack_type == "IA"
		DefenseType.DETECT:
			return attack_type == "PEP"
		DefenseType.RESPOND:
			return attack_type == "E/E"
		DefenseType.RECOVER:
			return true  # Wildcard - effective against all
		_:
			return false

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
	"""Record dice results and process connected attack chain logic with defense regression"""
	print("=== PROCESSING DICE RESULTS WITH ENHANCED AUTO-RESOLUTION ===")
	
	var round_results = []
	
	# Process each individual result
	for result in results:
		var position_index = result.attack_index
		var red_success = result.success
		var attack_data = current_attack_cards[position_index] if position_index < current_attack_cards.size() else null
		var defense_data = current_defense_cards[position_index] if position_index < current_defense_cards.size() else null
		
		if not attack_data:
			continue
			
		var result_data = {
			"position_index": position_index,
			"attack_name": result.attack_name,
			"defense_name": result.defense_name,
			"red_success": red_success,
			"blue_success": not red_success,
			"roll_result": result.roll_result,
			"auto_success": result.get("auto_success", false),
			"auto_failure": result.get("auto_failure", false),
			"invalid_play": result.get("invalid_play", false),
			"moderator_override": result.get("moderator_override", ""),
			"previous_state": get_step_name(attack_positions[position_index]["state"]),
			"intended_step": attack_data.card_type if attack_data else "Unknown",
			"defense_was_effective": false,
			"is_wildcard_defense": false,
			"auto_resolution_reason": result.get("auto_resolution_reason", "")
		}
		
		# Check if defense was effective in this engagement
		if defense_data and not result.get("auto_success", false) and not result.get("auto_failure", false):
			result_data.defense_was_effective = is_defense_effective_against_attack(defense_data.defense_type, attack_data.card_type)
			result_data.is_wildcard_defense = (defense_data.defense_type == DefenseType.RECOVER)
		
		# Apply results to connected attack chain with enhanced auto-resolution logic
		if result.get("invalid_play", false) or result.get("auto_failure", false):
			# Invalid plays or auto-failures don't change position state
			result_data.new_state = result_data.previous_state
			if result.get("auto_failure", false):
				print("Position ", position_index + 1, " - AUTO FAILURE: ", result.get("auto_resolution_reason", "Invalid red team play"))
			else:
				print("Position ", position_index + 1, " - INVALID PLAY: ", result.attack_name)
		elif result.get("moderator_override", "") in ["RED_WIN"]:
			# Moderator overrides bypass normal rules
			advance_position_state_forced(position_index, attack_data.card_type, result.get("moderator_override", ""))
			result_data.new_state = get_step_name(attack_positions[position_index]["state"])
			print("Position ", position_index + 1, " - MODERATOR RED WIN: Advanced to ", result_data.new_state)
		elif result.get("moderator_override", "") in ["BLUE_WIN"]:
			# Moderator blue win causes regression
			if defense_data and result_data.defense_was_effective:
				regress_position_state(position_index, defense_data.defense_type)
				result_data.new_state = get_step_name(attack_positions[position_index]["state"])
				print("Position ", position_index + 1, " - MODERATOR BLUE WIN: Regressed to ", result_data.new_state)
			else:
				result_data.new_state = result_data.previous_state
				print("Position ", position_index + 1, " - MODERATOR BLUE WIN: No regression (ineffective defense)")
		elif red_success or result.get("auto_success", false):
			# Red team wins (normal or auto) - advance normally
			var previous_state = attack_positions[position_index]["state"]
			advance_position_state(position_index, attack_data.card_type)
			result_data.new_state = get_step_name(attack_positions[position_index]["state"])
			if result.get("auto_success", false):
				print("Position ", position_index + 1, " - AUTO SUCCESS: ", result.get("auto_resolution_reason", "No/incompatible defense"), " - Advanced to ", result_data.new_state)
			else:
				print("Position ", position_index + 1, " - DICE SUCCESS: Advanced from ", result_data.previous_state, " to ", result_data.new_state)
		else:
			# Blue team wins (red fails) - check for regression
			if defense_data and result_data.defense_was_effective:
				regress_position_state(position_index, defense_data.defense_type)
				result_data.new_state = get_step_name(attack_positions[position_index]["state"])
				print("Position ", position_index + 1, " - BLUE SUCCESS: Regressed from ", result_data.previous_state, " to ", result_data.new_state)
			else:
				# Defense not effective or no defense - no change
				result_data.new_state = result_data.previous_state
				print("Position ", position_index + 1, " - BLUE SUCCESS: No regression (ineffective/no defense)")
		
		round_results.append(result_data)
	
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
	"""Advance a position state based on successful attack (with prerequisite checks)"""
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

func advance_position_state_forced(position_index: int, card_type: String, override_reason: String = ""):
	"""Force advance position state for moderator overrides (bypasses all checks)"""
	print("FORCED ADVANCEMENT: Position ", position_index + 1, " -> ", card_type, " (Reason: ", override_reason, ")")
	
	match card_type:
		"IA":
			attack_positions[position_index]["state"] = AttackStep.IA
		"PEP":
			# For moderator override, always allow PEP regardless of current state
			attack_positions[position_index]["state"] = AttackStep.PEP
		"E/E":
			# For moderator override, always allow E/E regardless of current state
			# This is the critical fix - moderator can force E/E win from any state
			attack_positions[position_index]["state"] = AttackStep.E_E
			print("FORCED E/E ACHIEVEMENT - RED TEAM VICTORY FORCED!")

func regress_position_state(position_index: int, defense_type: int):
	"""Regress position state when blue team wins with effective defense"""
	var current_state = attack_positions[position_index]["state"]
	
	if defense_type == DefenseType.RECOVER:
		# Wildcard recover resets to EMPTY
		attack_positions[position_index]["state"] = AttackStep.EMPTY
		print("RECOVER WILDCARD: Position ", position_index + 1, " reset to EMPTY")
	else:
		# Normal regression: go back one stage
		match current_state:
			AttackStep.E_E:
				attack_positions[position_index]["state"] = AttackStep.PEP
				print("DEFENSE SUCCESS: Position ", position_index + 1, " regressed from E/E to PEP")
			AttackStep.PEP:
				attack_positions[position_index]["state"] = AttackStep.IA
				print("DEFENSE SUCCESS: Position ", position_index + 1, " regressed from PEP to IA")
			AttackStep.IA:
				attack_positions[position_index]["state"] = AttackStep.EMPTY
				print("DEFENSE SUCCESS: Position ", position_index + 1, " regressed from IA to EMPTY")
			AttackStep.EMPTY:
				# Already at lowest state
				print("DEFENSE SUCCESS: Position ", position_index + 1, " already at EMPTY - no regression")

func process_defense_evictions():
	"""Process defense eviction cards that can reset positions - DEPRECATED"""
	# This function is kept for backwards compatibility but no longer used
	# The new defense system handles regression through regress_position_state()
	pass

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
	if not defense_card:
		return "No Defense"

	var card_index = defense_card.card_index
	if has_node("/root/Mitre"):
		var mitre = get_node("/root/Mitre")
		var key = card_index + 1
		if mitre.defend_dict.has(key):
			var entry = mitre.defend_dict[key]
			if entry.size() > 3:
				return entry[3]  # Name
			else:
				print("ERROR: Defense entry too short for index ", key, ": ", entry)
				return "Defense (Invalid Entry)"
		else:
			print("ERROR: Defense key not found in defend_dict: ", key)
			return "Defense (Missing)"
	return "Defense Card"

func get_attack_type(attack_card) -> String:
	"""Determine attack card type (IA, PEP, E/E) based on MITRE classification (1-3)"""
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
					_:
						return "IA"  # Default to IA
			else:
				print("Warning: Attack entry missing classification field for card_index: ", card_index)
				return "IA"
	
	print("Warning: Could not determine attack type for card_index: ", card_index)
	return "IA"  # Default

func get_defense_type(defense_card) -> int:
	"""Determine defense card type (1-4) based on database classification"""
	if not defense_card:
		return DefenseType.PROTECT  # Default
	
	var card_index = defense_card.card_index
	if has_node("/root/Mitre"):
		var mitre = get_node("/root/Mitre")
		if mitre.defend_dict.has(card_index + 1):
			var defense_entry = mitre.defend_dict[card_index + 1]
			# Try to find classification in the defense entry
			# This assumes there's a classification field - you may need to adjust based on actual database structure
			if defense_entry.size() > 6:
				# If there's a classification field at index 6
				var classification = int(defense_entry[6])
				if classification >= 1 and classification <= 4:
					return classification
			
			# If no classification field, determine by name patterns (fallback)
			var defense_name = defense_entry[3] if defense_entry.size() > 3 else ""
			return determine_defense_type_by_name(defense_name)
	
	print("Warning: Could not determine defense type for card_index: ", card_index)
	return DefenseType.PROTECT  # Default

func determine_defense_type_by_name(defense_name: String) -> int:
	"""Determine defense type by name patterns (fallback method)"""
	var name_lower = defense_name.to_lower()
	
	# Recover keywords
	if "recover" in name_lower or "restore" in name_lower or "reissue" in name_lower:
		return DefenseType.RECOVER
	
	# Respond keywords (for E/E attacks)
	if "respond" in name_lower or "terminat" in name_lower or "stop" in name_lower or "shutdown" in name_lower or "removal" in name_lower:
		return DefenseType.RESPOND
	
	# Detect keywords (for PEP attacks)
	if "detect" in name_lower or "monitor" in name_lower or "analysis" in name_lower or "discovery" in name_lower:
		return DefenseType.DETECT
	
	# Protect keywords (for IA attacks) - default
	return DefenseType.PROTECT

func get_defense_type_name(defense_type: int) -> String:
	"""Get readable name for defense type"""
	match defense_type:
		DefenseType.PROTECT:
			return "PROTECT"
		DefenseType.DETECT:
			return "DETECT"
		DefenseType.RESPOND:
			return "RESPOND"
		DefenseType.RECOVER:
			return "RECOVER"
		_:
			return "UNKNOWN"

func is_eviction_card(defense_card) -> bool:
	"""Check if defense card is an eviction card - DEPRECATED, use defense_type instead"""
	# Keep for backwards compatibility, but new system uses defense types
	if not defense_card:
		return false
	
	var defense_type = get_defense_type(defense_card)
	return defense_type == DefenseType.RECOVER or defense_type == DefenseType.RESPOND

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
		"Defense_1", "Defense_1_Type", "Defense_1_Maturity", "Defense_1_Effective",
		"Defense_2", "Defense_2_Type", "Defense_2_Maturity", "Defense_2_Effective",
		"Defense_3", "Defense_3_Type", "Defense_3_Maturity", "Defense_3_Effective",
		"Result_1", "Resolution_1", "Roll_1", "Red_Success_1", "Blue_Success_1", "New_State_1",
		"Result_2", "Resolution_2", "Roll_2", "Red_Success_2", "Blue_Success_2", "New_State_2", 
		"Result_3", "Resolution_3", "Roll_3", "Red_Success_3", "Blue_Success_3", "New_State_3",
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
		
		# Defense card data with new type system
		for i in range(3):
			if i < round_data.defense_cards.size() and round_data.defense_cards[i] != null:
				var defense = round_data.defense_cards[i]
				row.append(defense.name)
				row.append(get_defense_type_name(defense.defense_type))
				row.append(str(defense.maturity))
				# Check if defense was effective in this round's results
				var effective = false
				if round_data.has("results"):
					for result in round_data.results:
						if result.position_index == i:
							effective = result.get("defense_was_effective", false)
							break
				row.append("Yes" if effective else "No")
			else:
				row.append_array(["---", "---", "---", "---"])
		
		# Results data with new blue/red success tracking and resolution types
		for i in range(3):
			if i < round_data.results.size():
				var result = round_data.results[i]
				
				# Determine result description
				var result_desc = "Red_Success" if result.red_success else "Blue_Success"
				row.append(result_desc)
				
				# Determine resolution type
				var resolution_type = "Dice_Roll"
				if result.get("auto_success", false):
					resolution_type = "Auto_Success"
				elif result.get("auto_failure", false):
					resolution_type = "Auto_Failure"
				elif result.get("invalid_play", false):
					resolution_type = "Invalid_Play"
				elif result.get("moderator_override", "") != "":
					resolution_type = "Moderator_Override"
				row.append(resolution_type)
				
				row.append(str(result.roll_result) if result.has("roll_result") else "AUTO")
				row.append("Yes" if result.red_success else "No")
				row.append("Yes" if result.blue_success else "No")
				row.append(result.new_state)
			else:
				row.append_array(["---", "---", "---", "---", "---", "---"])
		
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
		
		# Enhanced round notes with auto-resolution info
		var auto_successes = 0
		var auto_failures = 0
		if round_data.has("results"):
			for result in round_data.results:
				if result.get("auto_success", false):
					auto_successes += 1
				elif result.get("auto_failure", false):
					auto_failures += 1
		
		var notes = "Round " + str(round_data.round_number) + " completed with enhanced defense system. "
		if auto_successes > 0 or auto_failures > 0:
			notes += "Auto-resolutions: " + str(auto_successes) + " red wins, " + str(auto_failures) + " red fails. "
		
		row.append(notes)
		
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

func debug_defense_type_matching():
	"""Debug function to show defense type matching"""
	print("=== DEFENSE TYPE MATCHING DEBUG ===")
	print("PROTECT (1) vs IA: ", is_defense_effective_against_attack(DefenseType.PROTECT, "IA"))
	print("PROTECT (1) vs PEP: ", is_defense_effective_against_attack(DefenseType.PROTECT, "PEP"))
	print("PROTECT (1) vs E/E: ", is_defense_effective_against_attack(DefenseType.PROTECT, "E/E"))
	print("DETECT (2) vs IA: ", is_defense_effective_against_attack(DefenseType.DETECT, "IA"))
	print("DETECT (2) vs PEP: ", is_defense_effective_against_attack(DefenseType.DETECT, "PEP"))
	print("DETECT (2) vs E/E: ", is_defense_effective_against_attack(DefenseType.DETECT, "E/E"))
	print("RESPOND (3) vs IA: ", is_defense_effective_against_attack(DefenseType.RESPOND, "IA"))
	print("RESPOND (3) vs PEP: ", is_defense_effective_against_attack(DefenseType.RESPOND, "PEP"))
	print("RESPOND (3) vs E/E: ", is_defense_effective_against_attack(DefenseType.RESPOND, "E/E"))
	print("RECOVER (4) vs IA: ", is_defense_effective_against_attack(DefenseType.RECOVER, "IA"))
	print("RECOVER (4) vs PEP: ", is_defense_effective_against_attack(DefenseType.RECOVER, "PEP"))
	print("RECOVER (4) vs E/E: ", is_defense_effective_against_attack(DefenseType.RECOVER, "E/E"))
	print("=== END DEFENSE MATCHING DEBUG ===")

func test_new_auto_resolution_rules():
	"""Comprehensive test of the new auto-resolution rules"""
	print("=== TESTING NEW AUTO-RESOLUTION RULES ===")
	
	print("\n1. Testing Red Team Invalid Plays (Should Auto-Fail):")
	
	# Simulate red team trying PEP without IA
	var mock_attack_pep = {"card_type": "PEP", "cost": 2, "time": 30, "name": "Test PEP Attack"}
	var mock_defense_detect = {"defense_type": DefenseType.DETECT, "maturity": 3, "name": "Test Detect Defense"}
	
	# Set position to EMPTY to make PEP invalid
	attack_positions[0]["state"] = AttackStep.EMPTY
	var pairing1 = create_individual_card_pairing(mock_attack_pep, mock_defense_detect, 0)
	
	print("  PEP attack when position EMPTY:")
	print("    Valid Play: ", pairing1.is_valid_play, " (should be false)")
	print("    Auto Failure: ", pairing1.get("auto_failure", false), " (should be true)")
	print("    Success Rate: ", pairing1.success_percentage, "% (should be 0)")
	print("    Status: ", pairing1.defense_match_status)
	
	# Simulate red team trying E/E without PEP
	var mock_attack_ee = {"card_type": "E/E", "cost": 3, "time": 45, "name": "Test E/E Attack"}
	var mock_defense_respond = {"defense_type": DefenseType.RESPOND, "maturity": 4, "name": "Test Respond Defense"}
	
	# Set position to IA to make E/E invalid (needs PEP)
	attack_positions[1]["state"] = AttackStep.IA
	var pairing2 = create_individual_card_pairing(mock_attack_ee, mock_defense_respond, 1)
	
	print("  E/E attack when position IA (needs PEP):")
	print("    Valid Play: ", pairing2.is_valid_play, " (should be false)")
	print("    Auto Failure: ", pairing2.get("auto_failure", false), " (should be true)")
	print("    Success Rate: ", pairing2.success_percentage, "% (should be 0)")
	print("    Status: ", pairing2.defense_match_status)
	
	print("\n2. Testing Blue Team Incompatible Defense (Should Auto-Win for Red):")
	
	# Simulate red team IA vs blue team DETECT (incompatible)
	var mock_attack_ia = {"card_type": "IA", "cost": 1, "time": 15, "name": "Test IA Attack"}
	var mock_defense_detect2 = {"defense_type": DefenseType.DETECT, "maturity": 2, "name": "Test Detect Defense"}
	
	# Set position to EMPTY to make IA valid
	attack_positions[2]["state"] = AttackStep.EMPTY
	var pairing3 = create_individual_card_pairing(mock_attack_ia, mock_defense_detect2, 2)
	
	print("  IA attack vs DETECT defense (incompatible):")
	print("    Valid Play: ", pairing3.is_valid_play, " (should be true)")
	print("    Defense Effective: ", pairing3.defense_effective, " (should be false)")
	print("    Auto Success: ", pairing3.auto_success, " (should be true)")
	print("    Success Rate: ", pairing3.success_percentage, "% (should be 100)")
	print("    Status: ", pairing3.defense_match_status)
	
	# Simulate red team PEP vs blue team PROTECT (incompatible)
	var mock_attack_pep2 = {"card_type": "PEP", "cost": 2, "time": 30, "name": "Test PEP Attack"}
	var mock_defense_protect = {"defense_type": DefenseType.PROTECT, "maturity": 3, "name": "Test Protect Defense"}
	
	# Set position to IA to make PEP valid
	attack_positions[0]["state"] = AttackStep.IA
	var pairing4 = create_individual_card_pairing(mock_attack_pep2, mock_defense_protect, 0)
	
	print("  PEP attack vs PROTECT defense (incompatible):")
	print("    Valid Play: ", pairing4.is_valid_play, " (should be true)")
	print("    Defense Effective: ", pairing4.defense_effective, " (should be false)")
	print("    Auto Success: ", pairing4.auto_success, " (should be true)")
	print("    Success Rate: ", pairing4.success_percentage, "% (should be 100)")
	print("    Status: ", pairing4.defense_match_status)
	
	print("\n3. Testing Compatible Scenarios (Should Require Dice):")
	
	# Simulate red team IA vs blue team PROTECT (compatible)
	var pairing5 = create_individual_card_pairing(mock_attack_ia, mock_defense_protect, 2)
	
	print("  IA attack vs PROTECT defense (compatible):")
	print("    Valid Play: ", pairing5.is_valid_play, " (should be true)")
	print("    Defense Effective: ", pairing5.defense_effective, " (should be true)")
	print("    Auto Success: ", pairing5.auto_success, " (should be false)")
	print("    Auto Failure: ", pairing5.get("auto_failure", false), " (should be false)")
	print("    Success Rate: ", pairing5.success_percentage, "% (should be < 100 and > 0)")
	print("    Status: ", pairing5.defense_match_status)
	
	# Simulate RECOVER wildcard (always compatible)
	var mock_defense_recover = {"defense_type": DefenseType.RECOVER, "maturity": 5, "name": "Test Recover Defense"}
	var pairing6 = create_individual_card_pairing(mock_attack_ia, mock_defense_recover, 2)
	
	print("  IA attack vs RECOVER defense (wildcard):")
	print("    Valid Play: ", pairing6.is_valid_play, " (should be true)")
	print("    Defense Effective: ", pairing6.defense_effective, " (should be true)")
	print("    Is Wildcard: ", pairing6.is_wildcard_defense, " (should be true)")
	print("    Auto Success: ", pairing6.auto_success, " (should be false)")
	print("    Auto Failure: ", pairing6.get("auto_failure", false), " (should be false)")
	print("    Success Rate: ", pairing6.success_percentage, "% (should be < 100)")
	print("    Status: ", pairing6.defense_match_status)
	
	print("\n=== AUTO-RESOLUTION RULES TEST COMPLETE ===")
	
	# Reset positions for normal gameplay
	for i in range(3):
		attack_positions[i]["state"] = AttackStep.EMPTY

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
				if defense_entry.size() > 6:
					print("Classification/Type (6): ", defense_entry[6])
			else:
				print("ERROR: Entry too short - expected at least 6 fields")
				
			# Test defense type determination
			var mock_card = {"card_index": card_index}
			var determined_type = get_defense_type(mock_card)
			print("Determined Defense Type: ", get_defense_type_name(determined_type), " (", determined_type, ")")
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
		print("  Defense: ", pairing.defense_name)
		print("  Defense Match: ", pairing.defense_match_status)
		print("  Defense Effective: ", pairing.defense_effective)
		if pairing.has("invalid_play"):
			print("  Invalid Play: ", pairing.invalid_play)
		print("")
	
	print("=== END PAIRING DEBUG ===")

# Call this function to run comprehensive debugging
func run_comprehensive_card_debug(attack_cards: Array, defense_cards: Array):
	"""Run all debugging functions"""
	print("\n" + "=".repeat(50))
	print("COMPREHENSIVE CARD DEBUG SESSION")
	print("=".repeat(50))
	
	test_attack_classification_mapping()
	debug_defense_type_matching()
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
		"Average_Defense_Maturity", "Defense_Effectiveness_Rate", "Notes"
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
		"Defense_1_Name", "Defense_1_Type", "Defense_1_Maturity", "Defense_1_Effective",
		"Defense_2_Name", "Defense_2_Type", "Defense_2_Maturity", "Defense_2_Effective",
		"Defense_3_Name", "Defense_3_Type", "Defense_3_Maturity", "Defense_3_Effective",
		"Total_Attack_Cost", "Total_Attack_Time", "Average_Defense_Maturity",
		"Defense_Match_Summary", "Blue_Team_Regression_Potential", "Round_Notes"
	]
	
	csv_data += ",".join(detailed_headers) + "\n"
	
	# Add round data
	for round_data in game_history:
		csv_data += generate_detailed_round_row(round_data) + "\n"
	
	return csv_data

func generate_game_summary_row() -> String:
	"""Generate overall game summary row with defense effectiveness stats"""
	var total_rounds = game_history.size()
	var red_victory = false
	var final_positions = ["EMPTY", "EMPTY", "EMPTY"]
	var most_advanced = "EMPTY"
	var total_attacks = 0
	var successful_attacks = 0
	var total_defenses = 0
	var effective_defenses = 0
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
				if result.get("red_success", false):
					successful_attacks += 1
				if result.get("defense_was_effective", false):
					effective_defenses += 1
	
	var avg_cost = total_cost / float(max(total_attacks, 1))
	var avg_time = total_time / float(max(total_attacks, 1))
	var avg_maturity = total_maturity / float(max(defense_count, 1))
	var defense_effectiveness = effective_defenses / float(max(total_defenses, 1)) * 100.0
	
	var game_duration = Time.get_time_string_from_system()  # This could be improved with actual duration tracking
	
	var notes = "Game completed with " + str(total_rounds) + " rounds using enhanced defense system with auto-resolution. "
	notes += "Red team " + ("won" if red_victory else "lost") + ". "
	notes += "Red success rate: " + str(int((successful_attacks / float(max(total_attacks, 1))) * 100)) + "%. "
	notes += "Defense effectiveness: " + str(int(defense_effectiveness)) + "%. "
	notes += "Auto-resolutions improve game flow by eliminating invalid plays."
	
	var row = [
		"SEACAT_Connected_Attack_Chain_Game_v3_Auto_Resolution",
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
		"%.1f" % defense_effectiveness + "%",
		notes
	]
	
	return ",".join(row)

func generate_detailed_round_row(round_data: Dictionary) -> String:
	"""Generate detailed round analysis row with defense matching info"""
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
	
	# Defense card details with type matching
	var defense_cards = round_data.get("defense_cards", [])
	for i in range(3):
		if i < defense_cards.size() and defense_cards[i] != null:
			var defense = defense_cards[i]
			row.append(defense.get("name", "---"))
			row.append(get_defense_type_name(defense.get("defense_type", DefenseType.PROTECT)))
			row.append(str(defense.get("maturity", "---")))
			# Check effectiveness from results
			var effective = false
			if round_data.has("results"):
				for result in round_data.results:
					if result.get("position_index", -1) == i:
						effective = result.get("defense_was_effective", false)
						break
			row.append("Yes" if effective else "No")
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
	
	# Defense match summary
	var match_summary = ""
	var regression_potential = ""
	var effective_defenses = 0
	var wildcard_defenses = 0
	
	if round_data.has("results"):
		for result in round_data.results:
			if result.get("defense_was_effective", false):
				effective_defenses += 1
			if result.get("is_wildcard_defense", false):
				wildcard_defenses += 1
	
	match_summary = str(effective_defenses) + "_effective_defenses"
	if wildcard_defenses > 0:
		match_summary += "_" + str(wildcard_defenses) + "_wildcards"
	
	regression_potential = "High" if effective_defenses > 0 else "None"
	
	row.append(match_summary)
	row.append(regression_potential)
	
	var notes = "Round " + str(round_data.get("round_number", 0)) + " with enhanced auto-resolution system. "
	notes += str(effective_defenses) + "/" + str(defense_count) + " defenses effective. "
	
	# Count auto-resolutions
	var auto_successes = 0
	var auto_failures = 0
	if round_data.has("results"):
		for result in round_data.results:
			if result.get("auto_success", false):
				auto_successes += 1
			elif result.get("auto_failure", false):
				auto_failures += 1
	
	if auto_successes > 0 or auto_failures > 0:
		notes += "Auto-resolutions: " + str(auto_successes) + " successes, " + str(auto_failures) + " failures. "
	
	notes += "Total cost: $" + str(total_cost) + ", Total time: " + str(total_time) + " min."
	row.append(notes)
	
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
		return "Position_Regressed_To_Empty"
	elif is_more_advanced(from_state, to_state):
		return "Defense_Regression_" + from_state + "_to_" + to_state
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
