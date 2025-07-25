extends Control

# Dice popup for SEACAT attack chain system
# Handles 1:1 card pairing, sequential rolling, and team announcements

# UI References - using get_node to avoid sizing issues
var attack_info_label
var defense_info_label
var dice_sprite
var number_label
var cup_sprite
var dice_result_label
var roll_button
var manual_toggle
var manual_entry
var manual_submit
var strength_info
var red_section
var blue_section
var result_indicator
var animation_player
var close_button
var admin_button

# Game state
var card_pairings = []
var current_pairing_index = 0
var rolling_results = []
var is_rolling = false
var manual_mode = false
var rolls_remaining = 0

# Dice faces (you'll need to add dice face textures)
var dice_faces = [
	"res://images/dice/dice_1.png",
	"res://images/dice/dice_2.png", 
	"res://images/dice/dice_3.png",
	"res://images/dice/dice_4.png",
	"res://images/dice/dice_5.png",
	"res://images/dice/dice_6.png",
	"res://images/dice/dice_7.png",
	"res://images/dice/dice_8.png",
	"res://images/dice/dice_9.png",
	"res://images/dice/dice_10.png"
]

# Signals
signal dice_completed(results: Array)
signal dice_cancelled()
signal defense_reallocation_complete()

func _ready():
	# Set proper size for the popup
	custom_minimum_size = Vector2(1152, 648)
	size = Vector2(1152, 648)
	
	# Get UI references
	get_ui_references()
	setup_ui()
	connect_signals()
	initialize_dice_session()

func get_ui_references():
	"""Get all UI node references"""
	attack_info_label = get_node("DialogPanel/InfoContainer/AttackInfo")
	defense_info_label = get_node("DialogPanel/InfoContainer/DefenseInfo")
	dice_sprite = get_node("DialogPanel/DiceContainer/DiceArea/DiceSprite")
	number_label = get_node("DialogPanel/DiceContainer/DiceArea/DiceSprite/NumberLabel")
	cup_sprite = get_node("DialogPanel/DiceContainer/DiceArea/CupSprite")
	dice_result_label = get_node("DialogPanel/DiceContainer/DiceResult")
	roll_button = get_node("DialogPanel/DiceContainer/ButtonContainer/RollButton")
	manual_toggle = get_node("DialogPanel/DiceContainer/ButtonContainer/ManualToggle")
	manual_entry = get_node("DialogPanel/DiceContainer/ManualEntry")
	manual_submit = get_node("DialogPanel/DiceContainer/ManualSubmit")
	strength_info = get_node("DialogPanel/StrengthContainer/StrengthInfo")
	red_section = get_node("DialogPanel/StrengthContainer/StrengthBar/RedSection")
	blue_section = get_node("DialogPanel/StrengthContainer/StrengthBar/BlueSection")
	result_indicator = get_node("DialogPanel/StrengthContainer/StrengthBar/ResultIndicator")
	animation_player = get_node("DialogPanel/DiceContainer/DiceArea/AnimationPlayer")
	close_button = get_node("DialogPanel/HeaderContainer/CloseButton")
	admin_button = get_node("DialogPanel/HeaderContainer/AdminButton")

func setup_ui():
	"""Setup initial UI state"""
	if manual_entry:
		manual_entry.visible = false
	if manual_submit:
		manual_submit.visible = false
	if result_indicator:
		result_indicator.visible = false
	
	# Load dice face (default to 5)
	update_dice_display(5)

func connect_signals():
	"""Connect UI signals"""
	if roll_button:
		roll_button.pressed.connect(_on_roll_button_pressed)
	if manual_toggle:
		manual_toggle.pressed.connect(_on_manual_toggle_pressed)
	if manual_submit:
		manual_submit.pressed.connect(_on_manual_submit_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	if admin_button:
		admin_button.pressed.connect(_on_admin_button_pressed)

func initialize_dice_session():
	"""Initialize the dice rolling session"""
	if not GameData:
		print("ERROR: GameData not available")
		if dice_result_label:
			dice_result_label.text = "Error: GameData not available"
		if roll_button:
			roll_button.disabled = true
		return
	
	# Debug: Show that we're using the attack table
	GameData.debug_show_attack_table()
	
	# Get card pairings from GameData
	card_pairings = GameData.get_card_pairing_info()
	
	if card_pairings.size() == 0:
		print("No active card pairings found")
		if dice_result_label:
			dice_result_label.text = "No active attacks to resolve"
		if roll_button:
			roll_button.disabled = true
		return
	
	print("Initialized dice session with ", card_pairings.size(), " card pairings")
	
	# Debug: Show pairing calculations
	GameData.debug_card_pairing_info()
	
	current_pairing_index = 0
	rolling_results.clear()
	rolls_remaining = card_pairings.size()
	
	# Display first pairing
	display_current_pairing()
	update_roll_button_text()

func display_current_pairing():
	"""Display information about the current card pairing"""
	if current_pairing_index >= card_pairings.size():
		return
	
	var pairing = card_pairings[current_pairing_index]
	
	# Update attack info
	if attack_info_label:
		var attack_text = "[b]Attack " + str(pairing.attack_index + 1) + " (" + pairing.current_step + "):[/b]\n"
		attack_text += pairing.attack_name
		attack_info_label.text = attack_text
	
	# Update defense info
	if defense_info_label:
		var defense_text = "[b]Defense " + str(pairing.attack_index + 1) + ":[/b]\n"
		if pairing.auto_success:
			defense_text += "[color=red]UNDEFENDED - AUTO SUCCESS[/color]"
		else:
			defense_text += pairing.defense_name
		defense_info_label.text = defense_text
	
	# Update strength bar and info
	update_strength_display(pairing)
	
	# Update dice result text
	if dice_result_label:
		if pairing.auto_success:
			dice_result_label.text = "Auto-Success! No roll needed."
		else:
			dice_result_label.text = "Ready to roll for Attack " + str(pairing.attack_index + 1)
	
	# Update roll button
	if roll_button:
		if pairing.auto_success:
			roll_button.text = "⚡ Auto-Resolve"
		else:
			roll_button.text = "🎲 Roll Dice"

func update_strength_display(pairing: Dictionary):
	"""Update the strength bar display"""
	var success_percentage = pairing.rounded_percentage
	var bar_width = 500.0
	var red_width = (success_percentage / 100.0) * bar_width
	
	# Update sections
	if red_section:
		red_section.size.x = red_width
	if blue_section:
		blue_section.position.x = red_width
		blue_section.size.x = bar_width - red_width
	
	# Update info text
	if strength_info:
		if pairing.auto_success:
			strength_info.text = "AUTO SUCCESS - No Defense Present"
		else:
			strength_info.text = "Success Rate: " + str(success_percentage) + "% | Roll " + str(pairing.dice_threshold) + " or lower to succeed"
			print("Displaying strength - Success Rate: ", success_percentage, "% Threshold: ", pairing.dice_threshold)

func update_roll_button_text():
	"""Update the roll button text with remaining rolls"""
	var remaining_text = ""
	if rolls_remaining > 1:
		remaining_text = " (" + str(rolls_remaining) + " Remaining)"
	elif rolls_remaining == 1:
		remaining_text = " (Last Roll)"
	
	if current_pairing_index < card_pairings.size():
		var pairing = card_pairings[current_pairing_index]
		if roll_button:
			if pairing.auto_success:
				roll_button.text = "⚡ Auto-Resolve" + remaining_text
			else:
				roll_button.text = "🎲 Roll Dice" + remaining_text

func _on_roll_button_pressed():
	"""Handle roll button press"""
	if is_rolling:
		return
	
	if current_pairing_index >= card_pairings.size():
		complete_all_rolls()
		return
	
	var pairing = card_pairings[current_pairing_index]
	
	if pairing.auto_success:
		handle_auto_success(pairing)
	else:
		if manual_mode:
			show_manual_entry()
		else:
			perform_dice_roll(pairing)

func handle_auto_success(pairing: Dictionary):
	"""Handle auto-success for undefended attacks"""
	var result = {
		"attack_index": pairing.attack_index,
		"attack_name": pairing.attack_name,
		"defense_name": pairing.defense_name,
		"roll_result": 0,  # No roll needed
		"success": true,
		"auto_success": true,
		"success_percentage": 100,
		"dice_threshold": 10
	}
	
	rolling_results.append(result)
	
	# Show team announcement
	show_team_announcement("🔴 RED TEAM WINS!", "Attack " + str(pairing.attack_index + 1) + " auto-succeeds (undefended)", Color.RED)
	
	# Wait for announcement, then continue
	await get_tree().create_timer(2.0).timeout
	advance_to_next_pairing()

func perform_dice_roll(pairing: Dictionary):
	"""Perform actual dice roll"""
	if is_rolling:
		return
	
	is_rolling = true
	if roll_button:
		roll_button.disabled = true
	
	# Animate dice roll
	await animate_dice_roll()
	
	# Generate result
	var roll_result = randi_range(1, 10)
	var success = roll_result <= pairing.dice_threshold
	
	# Store result
	var result = {
		"attack_index": pairing.attack_index,
		"attack_name": pairing.attack_name,
		"defense_name": pairing.defense_name,
		"roll_result": roll_result,
		"success": success,
		"auto_success": false,
		"success_percentage": pairing.rounded_percentage,
		"dice_threshold": pairing.dice_threshold
	}
	
	rolling_results.append(result)
	
	# Update dice display
	update_dice_display(roll_result)
	update_result_indicator(roll_result, pairing.dice_threshold)
	
	# Show result text
	if dice_result_label:
		var result_text = "Rolled: " + str(roll_result) + " (needed ≤" + str(pairing.dice_threshold) + ")\n"
		result_text += "Result: " + ("SUCCESS!" if success else "FAILURE")
		dice_result_label.text = result_text
	
	# Show team announcement
	var team_color = Color.RED if success else Color.BLUE
	var team_name = "🔴 RED TEAM WINS!" if success else "🔵 BLUE TEAM WINS!"
	var message = "Attack " + str(pairing.attack_index + 1) + " " + ("succeeds" if success else "fails") + " (rolled " + str(roll_result) + ")"
	
	show_team_announcement(team_name, message, team_color)
	
	# Wait for announcement, then continue
	await get_tree().create_timer(2.5).timeout
	
	is_rolling = false
	advance_to_next_pairing()

func animate_dice_roll() -> void:
	"""Animate the dice rolling"""
	var roll_duration = 1.5
	var roll_steps = 15
	var step_duration = roll_duration / roll_steps
	
	for i in range(roll_steps):
		var random_face = randi_range(1, 10)
		update_dice_display(random_face)
		await get_tree().create_timer(step_duration).timeout
	
	# Play cup reveal animation
	if animation_player:
		animation_player.play("cup_reveal")
		await animation_player.animation_finished

func update_dice_display(face_number: int):
	"""Update the dice sprite and number"""
	if number_label:
		number_label.text = str(face_number)
	
	# If you have dice face textures, load them here
	# For now, we'll just use the number display
	# if face_number >= 1 and face_number <= 10:
	#     dice_sprite.texture = load(dice_faces[face_number - 1])

func update_result_indicator(roll_result: int, threshold: int):
	"""Update the result indicator on the strength bar"""
	if not result_indicator:
		return
		
	var bar_width = 500.0
	var indicator_position = (roll_result / 10.0) * bar_width
	
	result_indicator.position.x = indicator_position - 2
	result_indicator.size.x = 4
	result_indicator.visible = true
	
	# Color based on success/failure
	if roll_result <= threshold:
		result_indicator.color = Color.GREEN
	else:
		result_indicator.color = Color.RED

func show_team_announcement(team_name: String, message: String, color: Color):
	"""Show team win announcement"""
	if dice_result_label:
		dice_result_label.text = "[center][color=" + color.to_html() + "]" + team_name + "[/color]\n" + message + "[/center]"
		dice_result_label.modulate = color

func advance_to_next_pairing():
	"""Advance to the next card pairing or complete"""
	current_pairing_index += 1
	rolls_remaining -= 1
	
	if current_pairing_index >= card_pairings.size():
		complete_all_rolls()
	else:
		# Reset UI for next roll
		if result_indicator:
			result_indicator.visible = false
		if dice_result_label:
			dice_result_label.modulate = Color.WHITE
		if roll_button:
			roll_button.disabled = false
		
		# Display next pairing
		display_current_pairing()
		update_roll_button_text()

func complete_all_rolls():
	"""Complete all dice rolls and return results"""
	print("All dice rolls completed. Results: ", rolling_results.size())
	
	# Show completion message
	if dice_result_label:
		dice_result_label.text = "[center]All attacks resolved!\nReturning to game...[/center]"
	if roll_button:
		roll_button.disabled = true
	
	# Wait a moment, then emit completion signal
	await get_tree().create_timer(1.5).timeout
	emit_signal("dice_completed", rolling_results)

func show_manual_entry():
	"""Show manual entry controls"""
	if manual_entry:
		manual_entry.visible = true
	if manual_submit:
		manual_submit.visible = true
	if roll_button:
		roll_button.visible = false

func _on_manual_toggle_pressed():
	"""Toggle between manual and automatic rolling"""
	manual_mode = !manual_mode
	
	if manual_toggle:
		if manual_mode:
			manual_toggle.text = "🎲 Auto Roll"
			if current_pairing_index < card_pairings.size():
				var pairing = card_pairings[current_pairing_index]
				if not pairing.auto_success and roll_button:
					roll_button.text = "✏️ Manual Entry"
		else:
			manual_toggle.text = "✏️ Manual Entry"
			if manual_entry:
				manual_entry.visible = false
			if manual_submit:
				manual_submit.visible = false
			if roll_button:
				roll_button.visible = true
			if current_pairing_index < card_pairings.size():
				var pairing = card_pairings[current_pairing_index]
				if roll_button:
					if pairing.auto_success:
						roll_button.text = "⚡ Auto-Resolve"
					else:
						roll_button.text = "🎲 Roll Dice"

func _on_manual_submit_pressed():
	"""Handle manual roll submission"""
	if current_pairing_index >= card_pairings.size() or not manual_entry:
		return
	
	var pairing = card_pairings[current_pairing_index]
	var manual_roll = int(manual_entry.value)
	
	# Validate roll
	if manual_roll < 1 or manual_roll > 10:
		if dice_result_label:
			dice_result_label.text = "Invalid roll! Must be between 1-10"
		return
	
	var success = manual_roll <= pairing.dice_threshold
	
	# Store result
	var result = {
		"attack_index": pairing.attack_index,
		"attack_name": pairing.attack_name,
		"defense_name": pairing.defense_name,
		"roll_result": manual_roll,
		"success": success,
		"auto_success": false,
		"success_percentage": pairing.rounded_percentage,
		"dice_threshold": pairing.dice_threshold
	}
	
	rolling_results.append(result)
	
	# Update display
	update_dice_display(manual_roll)
	update_result_indicator(manual_roll, pairing.dice_threshold)
	
	# Show result
	if dice_result_label:
		var result_text = "Manual Roll: " + str(manual_roll) + " (needed ≤" + str(pairing.dice_threshold) + ")\n"
		result_text += "Result: " + ("SUCCESS!" if success else "FAILURE")
		dice_result_label.text = result_text
	
	# Show team announcement
	var team_color = Color.RED if success else Color.BLUE
	var team_name = "🔴 RED TEAM WINS!" if success else "🔵 BLUE TEAM WINS!"
	var message = "Attack " + str(pairing.attack_index + 1) + " " + ("succeeds" if success else "fails") + " (manual roll " + str(manual_roll) + ")"
	
	show_team_announcement(team_name, message, team_color)
	
	# Hide manual controls
	if manual_entry:
		manual_entry.visible = false
	if manual_submit:
		manual_submit.visible = false
	if roll_button:
		roll_button.visible = true
	
	# Wait for announcement, then continue
	await get_tree().create_timer(2.5).timeout
	advance_to_next_pairing()

func _on_close_button_pressed():
	"""Handle close button press"""
	emit_signal("dice_cancelled")

func _on_admin_button_pressed():
	"""Handle admin/exit button press"""
	emit_signal("dice_cancelled")

func _input(event):
	"""Handle input events"""
	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
