extends Control

# Enhanced Dice popup with user-controlled flow, manual entry, and moderator controls
# FIXED: Unified flow to prevent duplicates and inconsistent state

# UI References
var attack_info_label
var defense_info_label
var dice_sprite
var number_label
var cup_sprite
var dice_result_label
var roll_button
var continue_button
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
var discussion_panel
var round_summary_label

# Moderator controls
var moderator_container
var red_win_button
var blue_win_button
var skip_button
var manual_entry_mod
var manual_submit_mod
var moderator_panel_visible = false

# Game state
var card_pairings = []
var current_pairing_index = 0
var rolling_results = []
var is_rolling = false
var is_waiting_for_user = false
var rolls_remaining = 0
var discussion_mode = false
var current_roll_result = 0

# UI state tracking
var ui_state = "ready"  # ready, rolling, result_shown, discussion

# FIXED: Add flag to prevent duplicate processing
var current_pairing_processed = false

# Dice position consistency - NEVER change this once set
var dice_base_position = Vector2(200, 75)
var dice_initialized = false

# Font resource
var kongtext_font = preload("res://pixel font/kongtext.ttf")

# Dice faces
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
signal discussion_completed()

func _ready():
	custom_minimum_size = Vector2(1152, 648)
	size = Vector2(1152, 648)
	
	get_ui_references()
	setup_ui()
	apply_font_everywhere()
	create_moderator_controls()
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
	manual_entry = get_node("DialogPanel/DiceContainer/ManualContainer/ManualEntryContainer/ManualEntry")
	manual_submit = get_node("DialogPanel/DiceContainer/ManualContainer/ManualButtonContainer/ManualSubmit")
	strength_info = get_node("DialogPanel/StrengthContainer/StrengthInfo")
	red_section = get_node("DialogPanel/StrengthContainer/StrengthBar/RedSection")
	blue_section = get_node("DialogPanel/StrengthContainer/StrengthBar/BlueSection")
	result_indicator = get_node("DialogPanel/StrengthContainer/StrengthBar/ResultIndicator")
	animation_player = get_node("DialogPanel/DiceContainer/DiceArea/AnimationPlayer")
	close_button = get_node("DialogPanel/HeaderContainer/CloseButton")
	admin_button = get_node("DialogPanel/HeaderContainer/AdminButton")
	
	# Initialize dice position ONCE and never change it again
	if dice_sprite and not dice_initialized:
		dice_sprite.position = dice_base_position
		dice_initialized = true
	
	# Create continue button in proper position
	create_continue_button()
	
	# Create discussion panel
	create_discussion_panel()

func apply_font_everywhere():
	"""Apply kongtext font to all UI elements"""
	var elements_to_font = [
		get_node("DialogPanel/HeaderContainer/TitleLabel"),
		get_node("DialogPanel/HeaderContainer/AdminButton"),
		get_node("DialogPanel/HeaderContainer/CloseButton"),
		attack_info_label,
		defense_info_label,
		dice_result_label,
		roll_button,
		manual_toggle,
		manual_submit,
		strength_info,
		number_label
	]
	
	for element in elements_to_font:
		if element:
			element.add_theme_font_override("font", kongtext_font)
			if element == number_label:
				element.add_theme_font_size_override("font_size", 28)
			elif element == get_node("DialogPanel/HeaderContainer/TitleLabel"):
				element.add_theme_font_size_override("font_size", 24)
			elif element == strength_info:
				element.add_theme_font_size_override("font_size", 18)
			elif element == dice_result_label:
				element.add_theme_font_size_override("font_size", 18)
			else:
				element.add_theme_font_size_override("font_size", 16)

func create_continue_button():
	"""Create a continue button positioned properly in the button container"""
	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "Continue"
	continue_button.visible = false
	continue_button.add_theme_font_override("font", kongtext_font)
	continue_button.add_theme_font_size_override("font_size", 16)
	
	# Insert at the beginning of button container to maintain layout
	var button_container = get_node("DialogPanel/DiceContainer/ButtonContainer")
	button_container.add_child(continue_button)
	button_container.move_child(continue_button, 0)  # Move to first position
	
	continue_button.pressed.connect(_on_continue_button_pressed)

func create_moderator_controls():
	"""Create moderator control panel with toggle between win buttons and manual entry"""
	# Create moderator container - initially hidden
	moderator_container = VBoxContainer.new()
	moderator_container.name = "ModeratorContainer"
	moderator_container.visible = false
	
	# Add to dice container, after the button container
	var dice_container = get_node("DialogPanel/DiceContainer")
	dice_container.add_child(moderator_container)
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	moderator_container.add_child(spacer)
	
	# Toggle button to switch between modes
	var mode_toggle = Button.new()
	mode_toggle.name = "ModeToggle"
	mode_toggle.text = "Switch to Probability Entry"
	mode_toggle.add_theme_font_override("font", kongtext_font)
	mode_toggle.add_theme_font_size_override("font_size", 14)
	mode_toggle.pressed.connect(_on_mode_toggle_pressed)
	moderator_container.add_child(mode_toggle)
	
	# Container for win buttons (Mode 1)
	var win_buttons_container = VBoxContainer.new()
	win_buttons_container.name = "WinButtonsContainer"
	moderator_container.add_child(win_buttons_container)
	
	var win_button_row = HBoxContainer.new()
	win_button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	win_buttons_container.add_child(win_button_row)
	
	# Red team auto-win button
	red_win_button = Button.new()
	red_win_button.text = "🔴 Red Wins"
	red_win_button.add_theme_font_override("font", kongtext_font)
	red_win_button.add_theme_font_size_override("font_size", 14)
	red_win_button.add_theme_color_override("font_color", Color.WHITE)
	red_win_button.modulate = Color.LIGHT_CORAL
	red_win_button.pressed.connect(_on_red_win_pressed)
	win_button_row.add_child(red_win_button)
	
	# Blue team auto-win button
	blue_win_button = Button.new()
	blue_win_button.text = "🔵 Blue Wins"
	blue_win_button.add_theme_font_override("font", kongtext_font)
	blue_win_button.add_theme_font_size_override("font_size", 14)
	blue_win_button.add_theme_color_override("font_color", Color.WHITE)
	blue_win_button.modulate = Color.LIGHT_BLUE
	blue_win_button.pressed.connect(_on_blue_win_pressed)
	win_button_row.add_child(blue_win_button)
	
	# Skip button
	skip_button = Button.new()
	skip_button.text = "⏭️ Skip"
	skip_button.add_theme_font_override("font", kongtext_font)
	skip_button.add_theme_font_size_override("font_size", 14)
	skip_button.add_theme_color_override("font_color", Color.WHITE)
	skip_button.modulate = Color.LIGHT_GRAY
	skip_button.pressed.connect(_on_skip_pressed)
	win_button_row.add_child(skip_button)
	
	# Container for manual entry (Mode 2) - initially hidden
	var manual_container = VBoxContainer.new()
	manual_container.name = "ManualContainer"
	manual_container.visible = false
	moderator_container.add_child(manual_container)
	
	var manual_label = Label.new()
	manual_label.text = "Set Success Probability:"
	manual_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	manual_label.add_theme_font_override("font", kongtext_font)
	manual_label.add_theme_font_size_override("font_size", 14)
	manual_label.add_theme_color_override("font_color", Color.WHITE)
	manual_container.add_child(manual_label)
	
	var manual_row = HBoxContainer.new()
	manual_row.alignment = BoxContainer.ALIGNMENT_CENTER
	manual_container.add_child(manual_row)
	
	# Probability entry spinbox (0-100%)
	manual_entry_mod = SpinBox.new()
	manual_entry_mod.min_value = 0.0
	manual_entry_mod.max_value = 100.0
	manual_entry_mod.value = 50.0
	manual_entry_mod.step = 10.0
	manual_entry_mod.suffix = "%"
	manual_entry_mod.alignment = HORIZONTAL_ALIGNMENT_CENTER
	manual_entry_mod.add_theme_font_override("font", kongtext_font)
	manual_entry_mod.add_theme_font_size_override("font_size", 14)
	manual_entry_mod.value_changed.connect(_on_probability_value_changed)  # Update bar when value changes
	manual_row.add_child(manual_entry_mod)
	
	# Manual submit button
	manual_submit_mod = Button.new()
	manual_submit_mod.text = "Roll with Probability"
	manual_submit_mod.add_theme_font_override("font", kongtext_font)
	manual_submit_mod.add_theme_font_size_override("font_size", 14)
	manual_submit_mod.pressed.connect(_on_manual_submit_mod_pressed)
	manual_row.add_child(manual_submit_mod)

func create_discussion_panel():
	"""Create discussion time panel with consistent formatting"""
	discussion_panel = Panel.new()
	discussion_panel.name = "DiscussionPanel"
	discussion_panel.visible = false
	discussion_panel.z_index = 200
	discussion_panel.anchors_preset = Control.PRESET_FULL_RECT
	add_child(discussion_panel)
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)
	bg.anchors_preset = Control.PRESET_FULL_RECT
	discussion_panel.add_child(bg)
	
	# Main content panel
	var content_panel = Panel.new()
	content_panel.position = Vector2(50, 30)
	content_panel.size = Vector2(1052, 588)
	discussion_panel.add_child(content_panel)
	
	# Title with proper font
	var title_label = Label.new()
	title_label.text = "Round Results Summary"
	title_label.position = Vector2(20, 15)
	title_label.size = Vector2(1012, 40)
	title_label.add_theme_font_override("font", kongtext_font)
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_panel.add_child(title_label)
	
	# Single RichTextLabel for all content - simpler approach
	round_summary_label = RichTextLabel.new()
	round_summary_label.position = Vector2(20, 70)
	round_summary_label.size = Vector2(1012, 450)
	round_summary_label.bbcode_enabled = true
	round_summary_label.fit_content = true
	round_summary_label.scroll_active = true
	round_summary_label.add_theme_font_override("normal_font", kongtext_font)
	round_summary_label.add_theme_font_override("bold_font", kongtext_font)
	round_summary_label.add_theme_font_size_override("normal_font_size", 14)
	round_summary_label.add_theme_color_override("default_color", Color.WHITE)
	content_panel.add_child(round_summary_label)
	
	# Continue button for discussion
	var discussion_continue = Button.new()
	discussion_continue.text = "Continue to Next Round"
	discussion_continue.position = Vector2(680, 535)
	discussion_continue.size = Vector2(200, 40)
	discussion_continue.add_theme_font_override("font", kongtext_font)
	discussion_continue.add_theme_font_size_override("font_size", 16)
	discussion_continue.pressed.connect(_on_discussion_continue_pressed)
	content_panel.add_child(discussion_continue)

func setup_ui():
	"""Setup initial UI state"""
	# Setup manual entry container visibility
	var manual_container = get_node_or_null("DialogPanel/DiceContainer/ManualContainer")
	if manual_container:
		manual_container.visible = false
	
	if manual_entry:
		manual_entry.add_theme_font_override("font", kongtext_font)
		manual_entry.add_theme_font_size_override("font_size", 16)
	if manual_submit:
		manual_submit.add_theme_font_override("font", kongtext_font)
		manual_submit.add_theme_font_size_override("font_size", 16)
	
	if result_indicator:
		result_indicator.visible = false
	
	# Move the strength container down by 25 pixels total
	var strength_container = get_node_or_null("DialogPanel/StrengthContainer")
	if strength_container:
		strength_container.position.y += 25
	
	# Set dice to default display without changing position
	set_dice_display_only(5)
	ui_state = "ready"

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
	"""Initialize the dice rolling session with individual card calculations"""
	if not GameData:
		print("ERROR: GameData not available")
		if dice_result_label:
			dice_result_label.text = "Error: GameData not available"
		if roll_button:
			roll_button.disabled = true
		return
	
	# Get individual card pairings from GameData with duplicate prevention
	card_pairings = get_unique_card_pairings()
	
	if card_pairings.size() == 0:
		print("No active card pairings found")
		if dice_result_label:
			dice_result_label.text = "No active attacks to resolve"
		if roll_button:
			roll_button.disabled = true
		return
	
	print("Initialized dice session with ", card_pairings.size(), " unique card pairings")
	
	# Show position state info
	show_position_state_info()
	
	current_pairing_index = 0
	rolling_results.clear()
	rolls_remaining = card_pairings.size()
	discussion_mode = false
	ui_state = "ready"
	current_pairing_processed = false  # FIXED: Initialize processing flag
	
	# Display first pairing
	display_current_pairing()
	update_roll_button_text()

func get_unique_card_pairings() -> Array:
	"""Get unique card pairings, preventing duplicates"""
	if not GameData or not GameData.has_method("get_card_pairing_info"):
		return []
	
	var raw_pairings = GameData.get_card_pairing_info()
	var unique_pairings = []
	var seen_attacks = {}
	
	for pairing in raw_pairings:
		var attack_key = str(pairing.attack_index) + "_" + pairing.attack_name
		if not seen_attacks.has(attack_key):
			seen_attacks[attack_key] = true
			unique_pairings.append(pairing)
			print("Added unique pairing: Attack ", pairing.attack_index + 1, " - ", pairing.attack_name)
		else:
			print("Skipped duplicate pairing: Attack ", pairing.attack_index + 1, " - ", pairing.attack_name)
	
	return unique_pairings

func show_position_state_info():
	"""Show current position states for context"""
	if not GameData:
		return
		
	var position_states = GameData.get_position_states_snapshot()
	print("=== CURRENT POSITION STATES ===")
	for state in position_states:
		print("Position ", state.position, ": ", state.state)
	print("=== END POSITION STATES ===")

func display_current_pairing():
	"""Display information about the current individual card pairing"""
	if current_pairing_index >= card_pairings.size():
		return
	
	# Ensure dice is in correct position before displaying
	force_dice_position()
	
	var pairing = card_pairings[current_pairing_index]
	
	# FIXED: Reset processing flag when displaying new pairing
	current_pairing_processed = false
	
	# Update attack info with individual card details
	if attack_info_label:
		var attack_text = "[b]Attack " + str(pairing.attack_index + 1) + " (" + pairing.intended_step + "):[/b]\n"
		attack_text += pairing.attack_name
		attack_text += "\n[color=yellow]Individual Stats:[/color]"
		attack_text += "\nCost: $" + str(pairing.individual_cost)
		attack_text += "\nTime: " + str(pairing.individual_time) + " minutes"
		var display_state = pairing.current_position_state
		if display_state == "EMPTY":
			display_state = "Unbreached"  # ← or "Secure", "Uncompromised", etc.

		attack_text += "\nCurrent Position: " + display_state
		
		if pairing.has("invalid_play") and pairing.invalid_play:
			attack_text += "\n[color=red]INVALID PLAY![/color]"
		
		attack_info_label.text = attack_text
	
	# Update defense info
	if defense_info_label:
		var defense_text = "[b]Defense " + str(pairing.attack_index + 1) + ":[/b]\n"
		if pairing.auto_success:
			defense_text += "[color=red]UNDEFENDED - AUTO SUCCESS[/color]"
		elif pairing.has("invalid_play") and pairing.invalid_play:
			defense_text += "[color=orange]PLAY INVALID - AUTO FAILURE[/color]"
		else:
			defense_text += pairing.defense_name
		defense_info_label.text = defense_text
	
	# Update strength bar and info with individual calculations
	update_strength_display(pairing)
	
	# Update dice result text based on current UI state  
	update_dice_result_text(pairing)
	
	# Update roll button
	update_roll_button_for_pairing(pairing)

func update_dice_result_text(pairing: Dictionary):
	"""Update dice result text based on current state"""
	if not dice_result_label:
		return
	
	match ui_state:
		"ready":
			if pairing.auto_success:
				dice_result_label.text = "Auto-Success! No roll needed."
				dice_result_label.modulate = Color.WHITE
			elif pairing.has("invalid_play") and pairing.invalid_play:
				dice_result_label.text = "Invalid play - Auto-Failure!"
				dice_result_label.modulate = Color.WHITE
			else:
				dice_result_label.text = "Ready to roll for Attack " + str(pairing.attack_index + 1)
				dice_result_label.text += "\nIndividual Success Rate: " + str(pairing.rounded_percentage) + "%"
				dice_result_label.modulate = Color.WHITE
		"rolling":
			dice_result_label.text = "Rolling dice for Attack " + str(pairing.attack_index + 1) + "..."
			dice_result_label.modulate = Color.WHITE
		"result_shown":
			if current_roll_result > 0:
				# FIXED: Check if this was a moderator override result and use correct threshold
				var display_threshold = pairing.dice_threshold
				var was_moderator_override = false
				
				# Check the most recent result for moderator override info
				if rolling_results.size() > 0:
					var latest_result = rolling_results[rolling_results.size() - 1]
					if latest_result.has("moderator_override") and latest_result.moderator_override == "MANUAL_PROBABILITY":
						if latest_result.has("custom_threshold"):
							display_threshold = latest_result.custom_threshold
							was_moderator_override = true
				
				var result_text = "Rolled: " + str(current_roll_result) + " (needed ≤" + str(int(display_threshold)) + ")\n"
				result_text += "Individual Stats: Cost " + str(pairing.individual_cost) + ", Time " + str(pairing.individual_time) + "\n"
				
				# FIXED: Use the correct threshold for success determination
				var success = current_roll_result <= display_threshold
				result_text += "Result: " + ("SUCCESS!" if success else "FAILURE")
				
				if was_moderator_override:
					result_text += " (Moderator Override)"
				
				dice_result_label.text = result_text
				dice_result_label.modulate = Color.RED if success else Color.BLUE
			else:
				# Auto success/failure cases
				if pairing.auto_success:
					dice_result_label.text = "AUTO SUCCESS - No Defense Present!"
					dice_result_label.modulate = Color.GREEN
				elif pairing.has("invalid_play") and pairing.invalid_play:
					dice_result_label.text = "INVALID PLAY - Auto Failure!"
					dice_result_label.modulate = Color.RED

func update_roll_button_for_pairing(pairing: Dictionary):
	"""Update roll button for current pairing and UI state"""
	if not roll_button:
		return
	
	match ui_state:
		"ready":
			roll_button.visible = true
			continue_button.visible = false
			
			if pairing.auto_success:
				roll_button.text = "⚡ Auto-Resolve (Success)"
			elif pairing.has("invalid_play") and pairing.invalid_play:
				roll_button.text = "❌ Auto-Resolve (Failure)"
			else:
				roll_button.text = "🎲 Roll Dice"
			
			# FIXED: Update remaining count properly
			update_roll_button_text_fixed()
			roll_button.disabled = false
			
		"rolling":
			roll_button.visible = false
			continue_button.visible = false
			if moderator_container:
				moderator_container.visible = false
			
		"result_shown":
			roll_button.visible = false
			continue_button.visible = true
			if moderator_container:
				moderator_container.visible = false
			# FIXED: Better remaining count for continue button
			if rolls_remaining > 1:
				continue_button.text = "Next Roll (" + str(rolls_remaining - 1) + " remaining)"
			else:
				continue_button.text = "Show Round Summary"

func update_strength_display(pairing: Dictionary):
	"""Update the strength bar display with individual card calculations"""
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
		elif pairing.has("invalid_play") and pairing.invalid_play:
			strength_info.text = "INVALID PLAY - Auto Failure"
		else:
			strength_info.text = "Individual Success Rate: " + str(success_percentage) + "% | Roll " + str(pairing.dice_threshold) + " or lower"
			strength_info.text += "\nBased on Cost: " + str(pairing.individual_cost) + ", Time: " + str(pairing.individual_time)

# FIXED: New function to properly update button text
func update_roll_button_text_fixed():
	"""Update the roll button text with accurate remaining count"""
	if not roll_button or ui_state != "ready":
		return
		
	var base_text = roll_button.text
	
	# Remove any existing remaining text
	if base_text.contains("("):
		var paren_index = base_text.find("(")
		base_text = base_text.substr(0, paren_index).strip_edges()
	
	var remaining_text = ""
	if rolls_remaining > 1:
		remaining_text = " (" + str(rolls_remaining) + " Remaining)"
	elif rolls_remaining == 1:
		remaining_text = " (Last Roll)"
	
	roll_button.text = base_text + remaining_text

func update_roll_button_text():
	"""Legacy function - redirects to fixed version"""
	update_roll_button_text_fixed()

func _on_roll_button_pressed():
	"""Handle roll button press"""
	if is_rolling or discussion_mode or ui_state != "ready" or current_pairing_processed:
		return
	
	if current_pairing_index >= card_pairings.size():
		show_discussion_time()
		return
	
	var pairing = card_pairings[current_pairing_index]
	
	if pairing.auto_success:
		handle_auto_success(pairing)
	elif pairing.has("invalid_play") and pairing.invalid_play:
		handle_auto_failure(pairing)
	else:
		# Always perform normal dice roll - moderator controls are separate
		perform_dice_roll(pairing)

# FIXED: Unified result processing function
func process_result_and_advance(result: Dictionary):
	"""Unified function to process results and advance consistently"""
	if current_pairing_processed:
		print("WARNING: Current pairing already processed, ignoring duplicate")
		return
	
	# Add result to collection
	rolling_results.append(result)
	current_pairing_processed = true
	
	print("DEBUG: Processed result for attack ", result.attack_index + 1, " (", result.attack_name, ")")
	print("DEBUG: Total results now: ", rolling_results.size())
	
	# Set UI to result shown
	ui_state = "result_shown"
	
	# Update UI for current pairing
	if current_pairing_index < card_pairings.size():
		var pairing = card_pairings[current_pairing_index]
		update_dice_result_text(pairing)
		update_roll_button_for_pairing(pairing)

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
		"dice_threshold": 10,
		"individual_cost": pairing.individual_cost,
		"individual_time": pairing.individual_time
	}
	
	current_roll_result = 0
	process_result_and_advance(result)  # FIXED: Use unified processing

func handle_auto_failure(pairing: Dictionary):
	"""Handle auto-failure for invalid plays"""
	var result = {
		"attack_index": pairing.attack_index,
		"attack_name": pairing.attack_name,
		"defense_name": pairing.defense_name,
		"roll_result": 0,  # No roll needed
		"success": false,
		"auto_success": false,
		"invalid_play": true,
		"success_percentage": 0,
		"dice_threshold": 10,
		"individual_cost": pairing.individual_cost,
		"individual_time": pairing.individual_time
	}
	
	current_roll_result = 0
	process_result_and_advance(result)  # FIXED: Use unified processing

func perform_dice_roll(pairing: Dictionary):
	if is_rolling or ui_state != "ready" or current_pairing_processed:
		return

	force_dice_position()

	is_rolling = true
	ui_state = "rolling"
	update_roll_button_for_pairing(pairing)
	update_dice_result_text(pairing)

	var roll_result = randi_range(1, 10)
	current_roll_result = roll_result

	# ⬇️ Don't set dice face yet
	await animate_dice_roll_simple(roll_result)

	var success = roll_result <= pairing.dice_threshold

	var result = {
		"attack_index": pairing.attack_index,
		"attack_name": pairing.attack_name,
		"defense_name": pairing.defense_name,
		"roll_result": roll_result,
		"success": success,
		"auto_success": false,
		"success_percentage": pairing.rounded_percentage,
		"dice_threshold": pairing.dice_threshold,
		"individual_cost": pairing.individual_cost,
		"individual_time": pairing.individual_time
	}

	update_result_indicator(roll_result, pairing.dice_threshold)

	is_rolling = false
	process_result_and_advance(result)

func animate_dice_roll_simple(final_result: int) -> void:
	# Step 1: Instantly hide the die
	if dice_sprite:
		dice_sprite.visible = false  # ⬅️ Move this up here

	# Step 2: Immediately play cup_cover — no delay
	if animation_player and animation_player.has_animation("cup_cover"):
		animation_player.play("cup_cover")
		await animation_player.animation_finished

	# Step 3: Set the dice face
	set_dice_display_only(final_result)

	# Step 4: Wait briefly if you want suspense
	await get_tree().create_timer(0.1).timeout  # Optional – reduce to 0.1s

	# Step 5: Show the dice (still hidden by cup)
	if dice_sprite:
		dice_sprite.visible = true

	# Step 6: Lift the cup
	if animation_player and animation_player.has_animation("cup_reveal"):
		animation_player.play("cup_reveal")
		await animation_player.animation_finished

	# Step 7: Force final position
	force_dice_position()

func set_dice_display_only(face_number: int):
	"""Update ONLY the dice display without touching position"""
	# ALWAYS ensure dice is in correct position first
	if dice_sprite:
		dice_sprite.position = dice_base_position
	
	if number_label:
		number_label.text = str(face_number)
	
	# Update dice sprite if available - DO NOT CHANGE POSITION
	if dice_sprite and face_number >= 1 and face_number <= 10:
		var face_index = face_number - 1
		if face_index < dice_faces.size():
			dice_sprite.texture = load(dice_faces[face_index])

func force_dice_position():
	"""Force dice back to base position - call this anywhere dice might move"""
	if dice_sprite:
		dice_sprite.position = dice_base_position

func update_result_indicator(roll_result: int, threshold: int):
	"""Update the result indicator on the strength bar"""
	if not result_indicator:
		return
		
	var bar_width = 500.0
	var indicator_position = (roll_result / 10.0) * bar_width
	
	result_indicator.position.x = indicator_position - 2
	result_indicator.size.x = 4
	result_indicator.visible = true
	
	# FIXED: Always use bright neon green for consistency
	result_indicator.color = Color.LIME  # Bright neon green

func update_result_indicator_for_probability(probability: float, success: bool):
	"""Update the result indicator on the strength bar for probability roll"""
	if not result_indicator:
		return
		
	var bar_width = 500.0
	# Position indicator based on the probability threshold
	var indicator_position = (probability / 100.0) * bar_width
	
	result_indicator.position.x = indicator_position - 2
	result_indicator.size.x = 4
	result_indicator.visible = true
	
	# FIXED: Always use bright neon green for consistency
	result_indicator.color = Color.LIME  # Bright neon green

func show_manual_entry():
	"""Show manual entry controls (legacy - kept for compatibility)"""
	var manual_container = get_node_or_null("DialogPanel/DiceContainer/ManualContainer")
	if manual_container:
		manual_container.visible = true

func _on_manual_toggle_pressed():
	"""Toggle moderator controls visibility"""
	if moderator_container:
		moderator_container.visible = !moderator_container.visible
		
		if not moderator_container.visible:
			# Reset to normal display when controls are hidden
			if current_pairing_index < card_pairings.size():
				var pairing = card_pairings[current_pairing_index]
				update_dice_result_text(pairing)

func _on_mode_toggle_pressed():
	"""Toggle between win buttons mode and manual entry mode"""
	var win_container = moderator_container.get_node("WinButtonsContainer")
	var manual_container = moderator_container.get_node("ManualContainer")
	var toggle_button = moderator_container.get_node("ModeToggle")
	
	if win_container.visible:
		# Switch to probability entry mode
		win_container.visible = false
		manual_container.visible = true
		toggle_button.text = "Switch to Win Buttons"
	else:
		# Switch to win buttons mode
		win_container.visible = true
		manual_container.visible = false
		toggle_button.text = "Switch to Probability Entry"

func _on_probability_value_changed(value):
	"""Update strength bar when probability value changes - preview only"""
	if current_pairing_index < card_pairings.size():
		update_strength_display_for_probability(value)
		# Hide result indicator during preview since no roll has happened yet
		if result_indicator:
			result_indicator.visible = false

# New moderator manual entry function with probability
func _on_manual_submit_mod_pressed():
	"""Handle probability-based roll submission from moderator controls"""
	if current_pairing_index >= card_pairings.size() or current_pairing_processed:
		return
	
	var pairing = card_pairings[current_pairing_index]
	var target_probability = manual_entry_mod.value  # 0-100%
	
	# Update the strength bar to show the custom probability
	update_strength_display_for_probability(target_probability)
	
	# Start rolling animation
	force_dice_position()
	is_rolling = true
	ui_state = "rolling"
	update_roll_button_for_pairing(pairing)
	update_dice_result_text(pairing)
	
	# Generate a random number 1-100 and check if it's <= target probability
	var random_roll = randi_range(1, 100)
	var success = random_roll <= target_probability
	
	# Convert to dice equivalent for display (1-10 scale)
	var dice_equivalent = int((random_roll / 10.0)) + 1
	if dice_equivalent > 10:
		dice_equivalent = 10
	
	current_roll_result = dice_equivalent
	
	# Animate the dice roll
	await animate_dice_roll_simple(dice_equivalent)
	
	# FIXED: Update result indicator showing where the random roll actually landed
	update_result_indicator_for_probability_roll(random_roll, target_probability, success)
	
	# Store result with individual card data and actual roll information
	var custom_threshold = target_probability / 10.0
	var result = {
		"attack_index": pairing.attack_index,
		"attack_name": pairing.attack_name,
		"defense_name": pairing.defense_name,
		"roll_result": dice_equivalent,
		"success": success,
		"auto_success": false,
		"moderator_override": "MANUAL_PROBABILITY",
		"success_percentage": target_probability,  # Use the custom probability
		"dice_threshold": custom_threshold,  # Store the custom threshold for display
		"custom_threshold": custom_threshold,  # Also store separately for clarity
		"individual_cost": pairing.individual_cost,
		"individual_time": pairing.individual_time,
		"random_roll": random_roll  # FIXED: Store the actual 1-100 roll that determined success/failure
	}
	
	# Hide moderator controls after use
	if moderator_container:
		moderator_container.visible = false
	
	# Custom result text for probability entry - FIXED: Show correct threshold
	if dice_result_label:
		dice_result_label.text = "PROBABILITY ROLL: " + str(target_probability) + "% chance set\n"
		dice_result_label.text += "Random: " + str(random_roll) + "/100 → " + ("SUCCESS!" if success else "FAILURE")
		dice_result_label.text += "\nDice equivalent: " + str(dice_equivalent) + " (needed ≤" + str(int(custom_threshold)) + ")"
		dice_result_label.modulate = Color.GREEN if success else Color.RED
	
	is_rolling = false
	process_result_and_advance(result)

func update_strength_display_for_probability(probability: float):
	"""Update the strength bar display with custom probability"""
	var bar_width = 500.0
	var red_width = (probability / 100.0) * bar_width
	
	# Update sections
	if red_section:
		red_section.size.x = red_width
	if blue_section:
		blue_section.position.x = red_width
		blue_section.size.x = bar_width - red_width
	
	# Update info text
	if strength_info:
		strength_info.text = "Custom Probability: " + str(probability) + "% | Moderator Override"

func update_result_indicator_for_probability_roll(random_roll: int, target_probability: float, success: bool):
	"""Update the result indicator showing where the actual random roll landed with offset"""
	if not result_indicator:
		return
		
	var bar_width = 500.0
	
	# FIXED: Position indicator based on where the random roll actually landed (1-100 scale)
	var roll_position_percent = random_roll / 100.0
	var base_indicator_position = roll_position_percent * bar_width
	
	# FIXED: Add offset to avoid landing exactly on the boundary
	var threshold_position = (target_probability / 100.0) * bar_width
	var offset = 0.0
	
	# If we're too close to the threshold boundary, add an offset
	var distance_to_threshold = abs(base_indicator_position - threshold_position)
	if distance_to_threshold < 3.0:  # Within 3 pixels of boundary
		if success:
			# Success: move indicator slightly left (into red/success zone)
			offset = -5.0
		else:
			# Failure: move indicator slightly right (into blue/failure zone)
			offset = 5.0
	
	var final_position = base_indicator_position + offset
	
	# Clamp to bar bounds
	final_position = clamp(final_position, 2.0, bar_width - 2.0)
	
	result_indicator.position.x = final_position - 2  # Center the 4px wide indicator
	result_indicator.size.x = 4
	result_indicator.visible = true
	
	# Color based on success/failure with enhanced visibility
	if success:
		result_indicator.color = Color.LIME_GREEN  # Brighter green for success
	else:
		result_indicator.color = Color.CRIMSON     # Brighter red for failure

func _on_manual_submit_pressed():
	"""Handle manual roll submission (legacy - using old manual entry)"""
	if current_pairing_index >= card_pairings.size() or not manual_entry or current_pairing_processed:
		return
	
	var pairing = card_pairings[current_pairing_index]
	var manual_roll = int(manual_entry.value)
	
	# Validate roll
	if manual_roll < 1 or manual_roll > 10:
		if dice_result_label:
			dice_result_label.text = "Invalid roll! Must be between 1-10"
		return
	
	current_roll_result = manual_roll
	var success = manual_roll <= pairing.dice_threshold
	
	# Store result with individual card data
	var result = {
		"attack_index": pairing.attack_index,
		"attack_name": pairing.attack_name,
		"defense_name": pairing.defense_name,
		"roll_result": manual_roll,
		"success": success,
		"auto_success": false,
		"moderator_override": "MANUAL_ENTRY",
		"success_percentage": pairing.rounded_percentage,
		"dice_threshold": pairing.dice_threshold,
		"individual_cost": pairing.individual_cost,
		"individual_time": pairing.individual_time
	}
	
	# Update display without changing position
	set_dice_display_only(manual_roll)
	update_result_indicator(manual_roll, pairing.dice_threshold)
	force_dice_position()
	
	# Hide manual controls
	var manual_container = get_node_or_null("DialogPanel/DiceContainer/ManualContainer")
	if manual_container:
		manual_container.visible = false
	if moderator_container:
		moderator_container.visible = false
	
	process_result_and_advance(result)  # FIXED: Use unified processing

# FIXED: All moderator control handlers now use unified processing and work correctly
func _on_red_win_pressed():
	"""Handle moderator red team auto-win - FIXED"""
	if current_pairing_index >= card_pairings.size() or current_pairing_processed:
		return
	
	var pairing = card_pairings[current_pairing_index]
	
	# Force success regardless of dice threshold or game state
	current_roll_result = 1  # Show as "perfect" roll
	
	var result = {
		"attack_index": pairing.attack_index,
		"attack_name": pairing.attack_name,
		"defense_name": pairing.defense_name,
		"roll_result": 1,
		"success": true,
		"auto_success": false,
		"moderator_override": "RED_WIN",
		"success_percentage": pairing.rounded_percentage,
		"dice_threshold": pairing.dice_threshold,
		"individual_cost": pairing.individual_cost,
		"individual_time": pairing.individual_time
	}
	
	# Update display
	set_dice_display_only(1)
	update_result_indicator(1, pairing.dice_threshold)
	force_dice_position()
	
	# Hide moderator controls after use
	if moderator_container:
		moderator_container.visible = false
	
	# Custom result text for moderator override
	if dice_result_label:
		dice_result_label.text = "MODERATOR OVERRIDE: Red Team Wins!\nAttack " + str(pairing.attack_index + 1) + " - FORCED SUCCESS"
		dice_result_label.text += "\nThis will bypass all game rules and force advancement"
		dice_result_label.modulate = Color.RED
	
	process_result_and_advance(result)
	
	print("DEBUG: Moderator Red win for attack index ", pairing.attack_index, " (", pairing.attack_name, ")")

func _on_blue_win_pressed():
	"""Handle moderator blue team auto-win - FIXED"""
	if current_pairing_index >= card_pairings.size() or current_pairing_processed:
		return
	
	var pairing = card_pairings[current_pairing_index]
	
	# Force failure regardless of dice threshold
	current_roll_result = 10  # Show as "worst" roll
	
	var result = {
		"attack_index": pairing.attack_index,
		"attack_name": pairing.attack_name,
		"defense_name": pairing.defense_name,
		"roll_result": 10,
		"success": false,
		"auto_success": false,
		"moderator_override": "BLUE_WIN",
		"success_percentage": pairing.rounded_percentage,
		"dice_threshold": pairing.dice_threshold,
		"individual_cost": pairing.individual_cost,
		"individual_time": pairing.individual_time
	}
	
	# Update display
	set_dice_display_only(10)
	update_result_indicator(10, pairing.dice_threshold)
	force_dice_position()
	
	# Hide moderator controls after use
	if moderator_container:
		moderator_container.visible = false
	
	# Custom result text for moderator override
	if dice_result_label:
		dice_result_label.text = "MODERATOR OVERRIDE: Blue Team Wins!\nAttack " + str(pairing.attack_index + 1) + " - FORCED FAILURE"
		dice_result_label.modulate = Color.BLUE
	
	process_result_and_advance(result)
	
	print("DEBUG: Moderator Blue win for attack index ", pairing.attack_index, " (", pairing.attack_name, ")")

func _on_skip_pressed():
	"""Handle moderator skip (no result) - FIXED"""
	if current_pairing_index >= card_pairings.size() or current_pairing_processed:
		return
	
	var pairing = card_pairings[current_pairing_index]
	
	# Create a "skipped" result that doesn't affect game state
	var result = {
		"attack_index": pairing.attack_index,
		"attack_name": pairing.attack_name,
		"defense_name": pairing.defense_name,
		"roll_result": 0,
		"success": false,
		"auto_success": false,
		"moderator_override": "SKIP",
		"skipped": true,
		"success_percentage": pairing.rounded_percentage,
		"dice_threshold": pairing.dice_threshold,
		"individual_cost": pairing.individual_cost,
		"individual_time": pairing.individual_time
	}
	
	current_roll_result = 0
	
	# Hide moderator controls after use
	if moderator_container:
		moderator_container.visible = false
	
	# Custom result text for skip
	if dice_result_label:
		dice_result_label.text = "MODERATOR OVERRIDE: Skipped\nAttack " + str(pairing.attack_index + 1) + " - No effect on game state"
		dice_result_label.modulate = Color.GRAY
	
	process_result_and_advance(result)
	
	print("DEBUG: Moderator Skip for attack index ", pairing.attack_index, " (", pairing.attack_name, ")")

func _on_continue_button_pressed():
	"""Handle continue button press - user-controlled flow"""
	if ui_state == "result_shown":
		advance_to_next_pairing()
	elif discussion_mode:
		complete_all_rolls()

func advance_to_next_pairing():
	"""Advance to the next card pairing or complete"""
	print("DEBUG: Advancing from pairing ", current_pairing_index, " to ", current_pairing_index + 1)
	print("DEBUG: Total pairings: ", card_pairings.size())
	print("DEBUG: Results so far: ", rolling_results.size())
	
	# FIXED: Only advance if we haven't already processed all pairings
	current_pairing_index += 1
	rolls_remaining -= 1
	
	if current_pairing_index >= card_pairings.size():
		print("DEBUG: All pairings complete, showing discussion")
		show_discussion_time()
	else:
		print("DEBUG: Moving to next pairing - Attack ", card_pairings[current_pairing_index].attack_index + 1, ": ", card_pairings[current_pairing_index].attack_name)
		
		# Reset UI for next roll
		if result_indicator:
			result_indicator.visible = false
		if moderator_container:
			moderator_container.visible = false
		
		ui_state = "ready"
		current_roll_result = 0
		current_pairing_processed = false  # FIXED: Reset processing flag
		
		# Ensure dice stays in correct position
		force_dice_position()
		
		# Display next pairing
		display_current_pairing()

func show_discussion_time():
	"""Show discussion time panel with round summary"""
	discussion_mode = true
	ui_state = "discussion"
	
	# Hide main dice interface
	var dialog_panel = get_node("DialogPanel")
	if dialog_panel:
		dialog_panel.visible = false
	
	# Show discussion panel
	if discussion_panel:
		discussion_panel.visible = true
	
	# Generate round summary
	generate_round_summary()

func generate_round_summary():
	"""Generate comprehensive round summary for discussion"""
	if not round_summary_label:
		return
	
	var summary_text = "[b][font_size=20]Attack Results[/font_size][/b]\n\n"
	
	# Individual results
	for i in range(rolling_results.size()):
		var result = rolling_results[i]
		summary_text += "[b]Attack " + str(result.attack_index + 1) + ":[/b] " + result.attack_name + "\n"
		summary_text += "Individual Stats: Cost " + str(result.individual_cost) + ", Time " + str(result.individual_time) + "\n"
		summary_text += "Defense: " + result.defense_name + "\n"
		
		if result.get("auto_success", false):
			summary_text += "[color=green]Result: AUTO SUCCESS (No Defense)[/color]\n"
		elif result.get("invalid_play", false):
			summary_text += "[color=red]Result: INVALID PLAY (Auto Failure)[/color]\n"
		elif result.get("skipped", false):
			summary_text += "[color=gray]Result: SKIPPED (No Effect)[/color]\n"
		elif result.get("moderator_override", "") != "":
			# FIXED: Simplified - all moderator overrides just show SUCCESS/FAILURE
			var success_text = "SUCCESS" if result.success else "FAILURE"
			var color = "green" if result.success else "red"
			var override_type = result.moderator_override
			
			if override_type == "RED_WIN":
				summary_text += "[color=red]Result: MODERATOR OVERRIDE - RED WINS[/color]\n"
			elif override_type == "BLUE_WIN":
				summary_text += "[color=blue]Result: MODERATOR OVERRIDE - BLUE WINS[/color]\n"
			elif override_type == "MANUAL_ENTRY":
				summary_text += "Manual Roll: " + str(result.roll_result) + "/10 (needed ≤" + str(result.dice_threshold) + ")\n"
				summary_text += "[color=" + color + "]Result: " + success_text + "[/color]\n"
			elif override_type == "MANUAL_PROBABILITY":
				summary_text += "Probability Roll: Custom probability set by moderator\n"
				summary_text += "[color=" + color + "]Result: " + success_text + "[/color]\n"
			else:
				# Catch-all for any other moderator overrides
				summary_text += "[color=" + color + "]Result: " + success_text + "[/color]\n"
		else:
			var success_text = "SUCCESS" if result.success else "FAILURE"
			var color = "green" if result.success else "red"
			summary_text += "Roll: " + str(result.roll_result) + "/10 (needed ≤" + str(result.dice_threshold) + ")\n"
			summary_text += "[color=" + color + "]Result: " + success_text + "[/color]\n"
		
		if i < rolling_results.size() - 1:
			summary_text += "\n"
	
	# Position states and actual changes
	summary_text += "\n\n[b][font_size=20]Position States & Changes[/font_size][/b]\n\n"
	
	# FIXED: Use our own rolling_results to determine changes instead of trying to access GameData
	for i in range(3):
		var current_state = get_current_position_state(i)
		
		# Pad current state to consistent width for alignment
		var padded_state = current_state.rpad(6)
		
		# Get the projected change based on our dice results
		var projected_change = get_projected_position_change(i)
		
		summary_text += "Position " + str(i + 1) + ": " + padded_state + " " + projected_change + "\n"
	
	# Red team victory condition
	summary_text += "\n[b][font_size=20]Victory Condition[/font_size][/b]\n"
	summary_text += "[color=red]When ANY position reaches E/E[/color]\n"
	summary_text += "[color=blue]Preventing this until time expires[/color]\n"
	
	
	round_summary_label.text = summary_text

func get_current_position_state(position_index: int) -> String:
	"""Get current position state from GameData"""
	if GameData and GameData.has_method("get_position_states_snapshot"):
		var position_states = GameData.get_position_states_snapshot()
		if position_index < position_states.size():
			var state = position_states[position_index].state
			return "EMPTY" if state == "EMPTY" else state
	return "EMPTY"

func get_projected_position_change(position_index: int) -> String:
	"""Get projected position change based on our dice results"""
	# Find the result for this position from our rolling_results
	for result in rolling_results:
		if result.attack_index == position_index:
			if result.get("skipped", false):
				return "[color=gray]→ Skipped[/color]"
			elif result.success:
				# Red team wins - determine advancement type
				var attack_type = get_attack_type_for_result(result)
				return get_advancement_text(position_index, attack_type)
			else:
				# Blue team wins - determine if there's regression
				return get_regression_text(position_index, result)
	
	# No attack found for this position
	return "[color=gray]No attack[/color]"

func get_attack_type_for_result(result: Dictionary) -> String:
	"""Determine attack type from result data"""
	# Try to get attack type from GameData if available
	if GameData and GameData.current_attack_cards.size() > result.attack_index:
		return GameData.current_attack_cards[result.attack_index].get("card_type", "IA")
	
	# Fallback - try to determine from attack name or default to IA
	return "IA"

func get_advancement_text(position_index: int, attack_type: String) -> String:
	"""Get advancement text based on current position and attack type"""
	var current_state = get_current_position_state(position_index)
	
	match attack_type:
		"IA":
			return "[color=yellow]→ Advance (IA established)[/color]"
		"PEP":
			if current_state == "IA":
				return "[color=yellow]→ Advance (IA → PEP)[/color]"
			else:
				return "[color=yellow]→ Advance (PEP)[/color]"
		"E/E":
			if current_state == "PEP":
				return "[color=red]→ VICTORY! (PEP → E/E)[/color]"
			else:
				return "[color=red]→ VICTORY! (E/E)[/color]"
		_:
			return "[color=yellow]→ Advance[/color]"

func get_regression_text(position_index: int, result: Dictionary) -> String:
	"""Get regression text when blue team wins"""
	var current_state = get_current_position_state(position_index)
	
	# Check if we have defense information from GameData
	if GameData and GameData.current_defense_cards.size() > position_index:
		var defense_card = GameData.current_defense_cards[position_index]
		if defense_card:
			var defense_type = GameData.get_defense_type(defense_card.card) if defense_card.has("card") else 1
			var attack_type = get_attack_type_for_result(result)
			
			# Check if defense is effective against the attack type
			var is_effective = GameData.is_defense_effective_against_attack(defense_type, attack_type)
			
			if is_effective:
				if defense_type == GameData.DefenseType.RECOVER:
					return "[color=blue]→ RESET (Recover defense)[/color]"
				else:
					# Show regression based on current state
					match current_state:
						"E/E":
							return "[color=blue]→ Regress (E/E → PEP)[/color]"
						"PEP":
							return "[color=blue]→ Regress (PEP → IA)[/color]"
						"IA":
							return "[color=blue]→ Regress (IA → EMPTY)[/color]"
						_:
							return "[color=blue]→ Regress[/color]"
			else:
				return "[color=gray]→ No change (ineffective defense)[/color]"
	
	# Fallback if we can't determine defense effectiveness
	return "[color=gray]→ No change[/color]"

func _on_discussion_continue_pressed():
	"""Handle discussion continue button press"""
	discussion_mode = false
	
	# Hide discussion panel
	if discussion_panel:
		discussion_panel.visible = false
	
	# Complete the round
	complete_all_rolls()

func complete_all_rolls():
	"""Complete all dice rolls and return results"""
	print("All dice rolls completed. Results: ", rolling_results.size())
	
	# FIXED: Verification - ensure we have the expected number of results
	if rolling_results.size() != card_pairings.size():
		print("WARNING: Result count mismatch! Expected: ", card_pairings.size(), ", Got: ", rolling_results.size())
		# Don't prevent completion, just warn
	
	# Show completion message briefly
	if dice_result_label:
		dice_result_label.text = "All attacks resolved!\nProcessing results..."
		dice_result_label.modulate = Color.WHITE
	
	# Wait a moment, then emit completion signal
	await get_tree().create_timer(1.0).timeout
	emit_signal("dice_completed", rolling_results)

func _on_close_button_pressed():
	"""Handle close button press"""
	emit_signal("dice_cancelled")

func _on_admin_button_pressed():
	"""Handle admin/exit button press"""
	emit_signal("dice_cancelled")

func _input(event):
	"""Handle input events"""
	if event.is_action_pressed("ui_cancel") and not discussion_mode:
		_on_close_button_pressed()
