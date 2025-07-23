extends Node

# Current attack/defense data (integrates with existing card system)
var current_attack_cards = []  # From aCards in game_screen
var current_defense_cards = []  # From dCards in game_screen
var current_attack_cost: int = 1
var current_attack_time: int = 1
var total_defense_maturity: float = 0.0

# Dice roll results
var last_dice_result: int = 0
var last_attack_success: bool = false
var dice_roll_completed: bool = false

# Team weights (calculated from cards)
var red_team_weight: int = 1
var blue_team_weight: int = 1

# Attack success rate table (cost vs time combinations)
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

signal dice_roll_requested
signal dice_roll_completed_signal

func _ready():
	reset_round_data()

func reset_round_data():
	"""Reset data for new round"""
	current_attack_cards.clear()
	current_defense_cards.clear()
	current_attack_cost = 1
	current_attack_time = 1
	total_defense_maturity = 0.0
	dice_roll_completed = false
	red_team_weight = 1
	blue_team_weight = 1

func capture_current_cards(attack_cards: Array, defense_cards: Array):
	"""Capture current state from game_screen cards"""
	current_attack_cards = attack_cards.duplicate()
	current_defense_cards = defense_cards.duplicate()
	
	calculate_attack_parameters()
	calculate_defense_effectiveness()
	calculate_team_weights()

func calculate_attack_parameters():
	"""Calculate combined attack cost and time from active attack cards"""
	var total_cost = 0
	var total_time = 0
	var card_count = 0
	
	for card in current_attack_cards:
		if card.inPlay and card.card_index != -1:
			total_cost += card.getCostValue()
			total_time += card.getTimeValue()
			card_count += 1
	
	if card_count > 0:
		# Use average for lookup, but clamp to 1-5 range
		current_attack_cost = clamp(int(total_cost / float(card_count)), 1, 5)
		current_attack_time = clamp(int(total_time / float(card_count) / 24), 1, 5)  # Convert minutes to 1-5 scale
	else:
		current_attack_cost = 1
		current_attack_time = 1

func calculate_defense_effectiveness():
	"""Calculate total defense maturity from active defense cards"""
	total_defense_maturity = 0.0
	var card_count = 0
	
	for card in current_defense_cards:
		if card.inPlay and card.card_index != -1:
			total_defense_maturity += card.getMaturityValue()
			card_count += 1
	
	if card_count > 0:
		total_defense_maturity = total_defense_maturity / float(card_count)
	else:
		total_defense_maturity = 1.0

func calculate_team_weights():
	"""Calculate team weights based on card efficiency"""
	# Red team weight: lower cost/time = higher weight
	var attack_efficiency = 0
	var attack_count = 0
	
	for card in current_attack_cards:
		if card.inPlay and card.card_index != -1:
			var cost = card.getCostValue()
			var time_factor = card.getTimeValue() / 24.0  # Normalize time to reasonable scale
			var efficiency = 6 - (cost + time_factor)  # Lower cost/time = higher efficiency
			attack_efficiency += efficiency
			attack_count += 1
	
	if attack_count > 0:
		red_team_weight = clamp(int(attack_efficiency / float(attack_count)), 1, 5)
	else:
		red_team_weight = 1
	
	# Blue team weight: higher maturity = higher weight
	blue_team_weight = clamp(int(total_defense_maturity), 1, 5)

func get_attack_success_rate() -> float:
	"""Get theoretical success rate for current attack parameters"""
	var key = "c" + str(current_attack_cost) + "t" + str(current_attack_time)
	var attack_data = attack_success_table.get(key, {"likelihood": 50})
	
	# Factor in defense effectiveness
	var base_likelihood = attack_data.likelihood / 100.0
	var defense_modifier = (total_defense_maturity - 1.0) / 4.0  # Convert 1-5 to 0-1
	var adjusted_likelihood = base_likelihood * (1.0 - (defense_modifier * 0.4))  # Max 40% reduction
	
	return clamp(adjusted_likelihood, 0.1, 0.9)

func get_dice_success_threshold() -> int:
	"""Get dice threshold for success (1-10 scale)"""
	var success_rate = get_attack_success_rate()
	# Convert success rate to threshold (higher rate = lower threshold)
	var threshold = int((1.0 - success_rate) * 10)
	return clamp(threshold, 1, 9)

func record_dice_result(result: int, success: bool):
	"""Record dice roll results"""
	last_dice_result = result
	last_attack_success = success
	dice_roll_completed = true
	emit_signal("dice_roll_completed_signal")

func get_current_attack_info() -> Dictionary:
	"""Get info about current attack for display"""
	var attack_names = []
	for card in current_attack_cards:
		if card.inPlay and card.card_index != -1:
			attack_names.append(Mitre.attack_dict[card.card_index + 1][2])
	
	return {
		"names": attack_names,
		"cost": current_attack_cost,
		"time": current_attack_time,
		"combined_name": " + ".join(attack_names) if attack_names.size() > 0 else "No Attack"
	}

func get_current_defense_info() -> Array:
	"""Get info about current defenses for display"""
	var defense_info = []
	for card in current_defense_cards:
		if card.inPlay and card.card_index != -1:
			defense_info.append({
				"name": Mitre.defend_dict[card.card_index + 1][2],
				"maturity": card.getMaturityValue()
			})
	return defense_info

func get_manual_likelihood() -> int:
	"""Convert current success rate to likelihood percentage for manual system fallback"""
	return int(get_attack_success_rate() * 100)
