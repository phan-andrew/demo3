extends Node

# Enhanced GameData - Attack Chain Progression System
# Handles 1:1 card pairing, dice calculations, and attack chain progression

# Attack chain progression system
enum AttackStep {
	IA,   # Initial Access (Step 1)
	PEP,  # Privilege Escalation/Persistence (Step 2) 
	E_E   # Execution/Exfiltration (Step 3) - WIN
}

# Attack line progress tracking
var attack_lines = [
	{"step": AttackStep.IA, "card_index": -1, "active": false},
	{"step": AttackStep.IA, "card_index": -1, "active": false},
	{"step": AttackStep.IA, "card_index": -1, "active": false}
]

# Current round data
var current_attack_cards = []
var current_defense_cards = []
var total_defense_maturity: float = 0.0

# Team weights (calculated from cards) - for compatibility
var red_team_weight: int = 1
var blue_team_weight: int = 1

# Legacy compatibility variables
var current_attack_cost: int = 1
var current_attack_time: int = 1
var last_dice_result: int = 0
var last_attack_success: bool = false

# Dice roll results for current round
var current_round_results = []
var dice_roll_completed: bool = false

# Attack success rate table
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

# Signals
signal dice_roll_completed_signal
signal defense_reallocation_needed
signal attack_chain_victory  # Red team wins - all attacks reach E/E
signal timeline_victory      # Blue team wins - time/timeline ends
signal dice_roll_requested   # Legacy compatibility

func _ready():
	reset_attack_chains()

func reset_attack_chains():
	"""Reset all attack chains to IA step"""
	for i in range(3):
		attack_lines[i] = {"step": AttackStep.IA, "card_index": -1, "active": false}
	current_round_results.clear()
	dice_roll_completed = false
	# Reset legacy compatibility variables
	red_team_weight = 1
	blue_team_weight = 1
	current_attack_cost = 1
	current_attack_time = 1
	last_dice_result = 0
	last_attack_success = false

func capture_current_cards(attack_cards: Array, defense_cards: Array):
	"""Capture current round cards and update attack line tracking"""
	current_attack_cards.clear()
	current_defense_cards.clear()
	
	print("Capturing cards - Attack cards: ", attack_cards.size(), " Defense cards: ", defense_cards.size())
	
	# Update attack lines and capture active cards
	for i in range(min(attack_cards.size(), 3)):
		var card = attack_cards[i]
		if card and card.inPlay == true and card.card_index != -1:
			current_attack_cards.append(card)
			attack_lines[i]["active"] = true
			attack_lines[i]["card_index"] = card.card_index
			print("Attack ", i + 1, " active: ", get_attack_name(card))
		else:
			attack_lines[i]["active"] = false
			attack_lines[i]["card_index"] = -1
	
	# Capture defense cards with 1:1 mapping
	for i in range(min(defense_cards.size(), 3)):
		var card = defense_cards[i]
		if card and card.inPlay == true and card.card_index != -1:
			current_defense_cards.append(card)
			print("Defense ", i + 1, " active: ", get_defense_name(card))
		else:
			current_defense_cards.append(null)
	
	calculate_defense_effectiveness()
	calculate_team_weights()
	calculate_attack_parameters()

func get_card_pairing_info() -> Array:
	"""Get 1:1 card pairing information for dice rolling"""
	var pairings = []
	
	print("Creating card pairings...")
	
	# Check active attacks and defenses
	var active_attacks = []
	var active_defenses = []
	
	for i in range(3):
		if attack_lines[i]["active"]:
			active_attacks.append(i)
		if i < current_defense_cards.size() and current_defense_cards[i] != null:
			active_defenses.append(i)
	
	print("Active attacks: ", active_attacks.size(), " Active defenses: ", active_defenses.size())
	
	# Handle defense reallocation if needed
	if active_defenses.size() > active_attacks.size() and active_attacks.size() > 0:
		print("Defense reallocation needed - more defenses than attacks")
		emit_signal("defense_reallocation_needed")
		return []  # Wait for reallocation
	
	# Create 1:1 pairings
	for i in range(3):
		if attack_lines[i]["active"]:
			var attack_card = get_attack_card_by_index(i)
			var defense_card = null
			if i < current_defense_cards.size():
				defense_card = current_defense_cards[i]
			
			var pairing = create_card_pairing(i, attack_card, defense_card)
			pairings.append(pairing)
			print("Created pairing for attack ", i + 1, ": ", pairing.attack_name, " vs ", pairing.defense_name)
	
	return pairings

func get_attack_card_by_index(index: int):
	"""Get attack card by its position index"""
	if index >= current_attack_cards.size():
		return null
	
	# Find the card at the specific index position
	var cards_found = 0
	for i in range(3):
		if attack_lines[i]["active"]:
			if cards_found == index:
				# Find the actual card with this card_index
				for card in current_attack_cards:
					if card and card.card_index == attack_lines[i]["card_index"]:
						return card
			cards_found += 1
	
	return null

func create_card_pairing(attack_index: int, attack_card, defense_card) -> Dictionary:
	"""Create a pairing between attack and defense card"""
	var pairing = {
		"attack_index": attack_index,
		"attack_name": "Unknown Attack",
		"defense_name": "No Defense",
		"success_percentage": 50.0,
		"rounded_percentage": 50,
		"dice_threshold": 5,
		"auto_success": false,
		"current_step": get_step_name(attack_lines[attack_index]["step"])
	}
	
	# Get attack info
	if attack_card:
		pairing["attack_name"] = get_attack_name(attack_card)
		
		# Calculate base success rate from table
		var base_rate = calculate_attack_success_rate(attack_card)
		print("Base success rate from table: ", base_rate * 100, "%")
		
		if defense_card == null:
			# No defense - auto success
			pairing["auto_success"] = true
			pairing["defense_name"] = "UNDEFENDED"
			pairing["success_percentage"] = 100.0
			pairing["rounded_percentage"] = 100
			pairing["dice_threshold"] = 10
			print("No defense - auto success")
		else:
			# Calculate success rate vs defense
			pairing["defense_name"] = get_defense_name(defense_card)
			var defense_modifier = calculate_defense_modifier(defense_card)
			var final_rate = base_rate * (1.0 - defense_modifier)
			
			pairing["success_percentage"] = final_rate * 100.0
			pairing["rounded_percentage"] = round_to_nearest_ten(pairing["success_percentage"])
			pairing["dice_threshold"] = pairing["rounded_percentage"] / 10
			
			print("Defense modifier: ", defense_modifier, " Final rate: ", final_rate * 100, "% Rounded: ", pairing["rounded_percentage"], "% Threshold: ", pairing["dice_threshold"])
	
	return pairing

func calculate_attack_success_rate(attack_card) -> float:
	"""Calculate base attack success rate from attack card using the success table"""
	var cost = 1
	var time = 1
	
	if attack_card.has_method("getCostValue"):
		cost = clamp(attack_card.getCostValue(), 1, 5)
	if attack_card.has_method("getTimeValue"):
		time = clamp(int(attack_card.getTimeValue() / 24), 1, 5)  # Convert to 1-5 scale
	
	var key = "c" + str(cost) + "t" + str(time)
	var attack_data = attack_success_table.get(key, {"likelihood": 50})
	var base_rate = attack_data.likelihood / 100.0
	
	print("Attack success calculation - Cost: ", cost, " Time: ", time, " Key: ", key, " Base Rate: ", base_rate * 100, "%")
	
	return base_rate

func calculate_defense_modifier(defense_card) -> float:
	"""Calculate defense effectiveness modifier (0.0 to 0.4)"""
	var maturity = 1
	if defense_card.has_method("getMaturityValue"):
		maturity = defense_card.getMaturityValue()
	
	# Convert maturity (1-5) to modifier (0-40% reduction)
	return (maturity - 1.0) / 4.0 * 0.4

func round_to_nearest_ten(percentage: float) -> int:
	"""Round percentage to nearest 10 for dice threshold"""
	return int(round(percentage / 10.0) * 10)

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

func record_dice_results(results: Array):
	"""Record dice results and advance attack chains"""
	current_round_results = results.duplicate()
	dice_roll_completed = true
	
	print("Recording dice results: ", results.size(), " results")
	
	# Process each result and advance attack chains
	for result in results:
		var attack_index = result.attack_index
		print("Processing result for attack ", attack_index + 1, ": ", "Success" if result.success else "Failure")
		if result.success:
			advance_attack_chain(attack_index)
	
	# Check win conditions
	if check_all_attacks_complete():
		print("All attacks completed - Red team victory!")
		emit_signal("attack_chain_victory")
	
	emit_signal("dice_roll_completed_signal")

func advance_attack_chain(attack_index: int):
	"""Advance an attack chain to the next step"""
	if attack_index < 0 or attack_index >= 3:
		return
	
	var current_step = attack_lines[attack_index]["step"]
	
	match current_step:
		AttackStep.IA:
			attack_lines[attack_index]["step"] = AttackStep.PEP
			print("Attack ", attack_index + 1, " advanced to PEP")
		AttackStep.PEP:
			attack_lines[attack_index]["step"] = AttackStep.E_E
			print("Attack ", attack_index + 1, " advanced to E/E")
		AttackStep.E_E:
			print("Attack ", attack_index + 1, " already at E/E")

func check_all_attacks_complete() -> bool:
	"""Check if ALL active attacks have reached E/E"""
	var active_attacks = 0
	var completed_attacks = 0
	
	for i in range(3):
		if attack_lines[i]["active"]:
			active_attacks += 1
			if attack_lines[i]["step"] == AttackStep.E_E:
				completed_attacks += 1
	
	return active_attacks > 0 and completed_attacks == active_attacks

func get_step_name(step: AttackStep) -> String:
	"""Get readable name for attack step"""
	match step:
		AttackStep.IA:
			return "IA"
		AttackStep.PEP:
			return "PEP"
		AttackStep.E_E:
			return "E/E"
		_:
			return "Unknown"

func get_attack_chain_progress() -> Array:
	"""Get progress info for all attack chains"""
	var progress_info = []
	
	for i in range(3):
		var info = {
			"attack_index": i,
			"active": attack_lines[i]["active"],
			"current_step": get_step_name(attack_lines[i]["step"]),
			"step_number": int(attack_lines[i]["step"]) + 1,
			"progress_percentage": float(int(attack_lines[i]["step"]) + 1) / 3.0,
			"completed": attack_lines[i]["step"] == AttackStep.E_E
		}
		progress_info.append(info)
	
	return progress_info

func calculate_defense_effectiveness():
	"""Calculate combined defense effectiveness"""
	total_defense_maturity = 0.0
	var active_defenses = 0
	
	for defense_card in current_defense_cards:
		if defense_card != null:
			if defense_card.has_method("getMaturityValue"):
				total_defense_maturity += defense_card.getMaturityValue()
			else:
				total_defense_maturity += 1.0
			active_defenses += 1
	
	if active_defenses > 0:
		total_defense_maturity = total_defense_maturity / float(active_defenses)
	else:
		total_defense_maturity = 1.0

func calculate_team_weights():
	"""Calculate team weights based on card efficiency (legacy compatibility)"""
	# Red team weight: lower cost/time = higher weight
	var attack_efficiency = 0
	var attack_count = 0
	
	for card in current_attack_cards:
		if card and card.inPlay == true and card.card_index != -1:
			var cost = 1
			var time_factor = 1
			
			if card.has_method("getCostValue"):
				cost = card.getCostValue()
			if card.has_method("getTimeValue"):
				time_factor = card.getTimeValue() / 24.0  # Normalize time to reasonable scale
			
			var efficiency = 6 - (cost + time_factor)  # Lower cost/time = higher efficiency
			attack_efficiency += efficiency
			attack_count += 1
	
	if attack_count > 0:
		red_team_weight = clamp(int(attack_efficiency / float(attack_count)), 1, 5)
	else:
		red_team_weight = 1
	
	# Blue team weight: higher maturity = higher weight
	blue_team_weight = clamp(int(total_defense_maturity), 1, 5)

func calculate_attack_parameters():
	"""Calculate combined attack cost and time (legacy compatibility)"""
	var total_cost = 0
	var total_time = 0
	var card_count = 0
	
	for card in current_attack_cards:
		if card and card.inPlay == true and card.card_index != -1:
			if card.has_method("getCostValue"):
				total_cost += card.getCostValue()
			else:
				total_cost += 1  # Default fallback
				
			if card.has_method("getTimeValue"):
				total_time += card.getTimeValue()
			else:
				total_time += 1  # Default fallback
			card_count += 1
	
	if card_count > 0:
		# Use average for lookup, but clamp to 1-5 range
		current_attack_cost = clamp(int(total_cost / float(card_count)), 1, 5)
		current_attack_time = clamp(int(total_time / float(card_count) / 24), 1, 5)  # Convert minutes to 1-5 scale
	else:
		current_attack_cost = 1
		current_attack_time = 1

func reset_round_data():
	"""Reset data for new round (keep attack chain progress)"""
	current_round_results.clear()
	dice_roll_completed = false
	# Note: We DON'T reset attack_lines here - they persist across rounds

# Export functions for CSV compatibility
func export_to_csv_format() -> Array:
	"""Export current state for CSV logging"""
	var row = []
	
	# Add attack cards
	for i in range(3):
		if attack_lines[i]["active"]:
			var attack_card = get_attack_card_by_index(i)
			if attack_card and attack_card.has_method("getString"):
				row.append(attack_card.getString())
			else:
				row.append("Attack " + str(i + 1))
		else:
			row.append("---")
	
	# Add defense cards
	for i in range(3):
		if i < current_defense_cards.size() and current_defense_cards[i] != null:
			var defense_card = current_defense_cards[i]
			if defense_card.has_method("getString"):
				row.append(defense_card.getString())
			else:
				row.append("Defense " + str(i + 1))
		else:
			row.append("---")
	
	# Add individual roll results
	for i in range(3):
		var found_result = false
		for result in current_round_results:
			if result.attack_index == i:
				row.append(result.roll_result if not result.auto_success else "AUTO")
				row.append("Success" if result.success else "Failure")
				found_result = true
				break
		
		if not found_result:
			row.append("---")
			row.append("---")
	
	# Add overall results
	var overall_success = false
	for result in current_round_results:
		if result.success:
			overall_success = true
			break
	
	row.append("Success" if overall_success else "Failure")
	row.append("---")  # Risk analysis placeholder
	
	# Add attack chain steps
	var progress_info = get_attack_chain_progress()
	for i in range(3):
		if i < progress_info.size():
			row.append(progress_info[i].current_step)
		else:
			row.append("---")
	
	return row

# Legacy compatibility functions
func get_attack_success_rate() -> float:
	"""Get theoretical success rate for current attack parameters (legacy)"""
	var key = "c" + str(current_attack_cost) + "t" + str(current_attack_time)
	var attack_data = attack_success_table.get(key, {"likelihood": 50})
	
	# Factor in defense effectiveness
	var base_likelihood = attack_data.likelihood / 100.0
	var defense_modifier = (total_defense_maturity - 1.0) / 4.0  # Convert 1-5 to 0-1
	var adjusted_likelihood = base_likelihood * (1.0 - (defense_modifier * 0.4))  # Max 40% reduction
	
	return clamp(adjusted_likelihood, 0.1, 0.9)

func get_dice_success_threshold() -> int:
	"""Get dice threshold for success (1-10 scale) (legacy)"""
	var success_rate = get_attack_success_rate()
	# Convert success rate to threshold (higher rate = lower threshold)
	var threshold = int((1.0 - success_rate) * 10)
	return clamp(threshold, 1, 9)

func record_dice_result(result: int, success: bool):
	"""Record dice roll results (legacy compatibility)"""
	last_dice_result = result
	last_attack_success = success
	dice_roll_completed = true
	emit_signal("dice_roll_completed_signal")

func request_dice_roll():
	"""Request transition to dice rolling scene (legacy)"""
	emit_signal("dice_roll_requested")

func should_use_dice_system() -> bool:
	"""Check if conditions are met to use automated dice system (legacy)"""
	# Use dice system if we have at least one attack card
	for card in current_attack_cards:
		if card and card.inPlay == true and card.card_index != -1:
			return true
	return false

func get_manual_likelihood() -> int:
	"""Convert current success rate to likelihood percentage for manual system fallback (legacy)"""
	return int(get_attack_success_rate() * 100)

func debug_show_attack_table():
	"""Debug function to show attack success table entries"""
	print("=== ATTACK SUCCESS RATE TABLE ===")
	for key in attack_success_table.keys():
		var entry = attack_success_table[key]
		print(key, " -> Cost:", entry.cost, " Time:", entry.time, " Likelihood:", entry.likelihood, "%")
	print("=== END TABLE ===")

func debug_card_pairing_info():
	"""Debug function to show current card pairing calculations"""
	print("=== CARD PAIRING DEBUG ===")
	var pairings = get_card_pairing_info()
	for i in range(pairings.size()):
		var pairing = pairings[i]
		print("Pairing ", i + 1, ":")
		print("  Attack: ", pairing.attack_name, " (Step: ", pairing.current_step, ")")
		print("  Defense: ", pairing.defense_name)
		print("  Success Rate: ", pairing.success_percentage, "% -> Rounded: ", pairing.rounded_percentage, "%")
		print("  Dice Threshold: ", pairing.dice_threshold, " (Roll ≤", pairing.dice_threshold, " to succeed)")
		print("  Auto Success: ", pairing.auto_success)
	print("=== END PAIRING DEBUG ===")
