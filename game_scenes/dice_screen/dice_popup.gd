extends Control

# Enhanced Dice popup with user-controlled flow, manual entry, and moderator controls
# Fixes: Manual entry functionality, moderator controls, consistent formatting

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
	manual_entry = get_node("DialogPanel/DiceContainer/ManualContainer/ManualEntry")
	manual_submit = get_node("DialogPanel/DiceContainer/ManualContainer/ManualSubmit")
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
	"""Create moderator control panel with consistent formatting"""
	# Create moderator container - initially hidden
	moderator_container = VBoxContainer.new()
	moderator_container.name = "ModeratorContainer"
	moderator_container.visible = false
	
	# Add to dice container, after the button container
	var dice_container = get_node("DialogPanel/DiceContainer")
	dice_container.add_child(moderator_container)
	
	# Add spacing
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	moderator_container.add_child(spacer)
	
	# Moderator title
	var mod_title = Label.new()
	mod_title.text = "Moderator Controls"
	mod_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mod_title.add_theme_font_override("font", kongtext_font)
	mod_title.add_theme_font_size_override("font_size", 18)
	mod_title.add_theme_color_override("font_color", Color.YELLOW)
	moderator_container.add_child(mod_title)
	
	# Button container for moderator controls
	var mod_button_container = HBoxContainer.new()
	mod_button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	moderator_container.add_child(mod_button_container)
	
	# Red team auto-win button
	red_win_button = Button.new()
	red_win_button.text = "🔴 Red Wins"
	red_win_button.add_theme_font_override("font", kongtext_font)
	red_win_button.add_theme_font_size_override("font_size", 16)
	red_win_button.add_theme_color_override("font_color", Color.WHITE)
	red_win_button.modulate = Color.LIGHT_CORAL
	red_win_button.pressed.connect(_on_red_win_pressed)
	mod_button_container.add_child(red_win_button)
	
	# Blue team auto-win button
	blue_win_button = Button.new()
	blue_win_button.text = "🔵 Blue Wins"
	blue_win_button.add_theme_font_override("font", kongtext_font)
	blue_win_button.add_theme_font_size_override("font_size", 16)
	blue_win_button.add_theme_color_override("font_color", Color.WHITE)
	blue_win_button.modulate = Color.LIGHT_BLUE
	blue_win_button.pressed.connect(_on_blue_win_pressed)
	mod_button_container.add_child(blue_win_button)
	
	# Skip button
	skip_button = Button.new()
	skip_button.text = "⏭️ Skip (No Result)"
	skip_button.add_theme_font_override("font", kongtext_font)
	skip_button.add_theme_font_size_override("font_size", 16)
	skip_button.add_theme_color_override("font_color", Color.WHITE)
	skip_button.modulate = Color.LIGHT_GRAY
	skip_button.pressed.connect(_on_skip_pressed)
	mod_button_container.add_child(skip_button)

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
	
	# Update attack info with individual card details
	if attack_info_label:
		var attack_text = "[b]Attack " + str(pairing.attack_index + 1) + " (" + pairing.intended_step + "):[/b]\n"
		attack_text += pairing.attack_name
		attack_text += "\n[color=yellow]Individual Stats:[/color]"
		attack_text += "\nCost: $" + str(pairing.individual_cost)
		attack_text += "\nTime: " + str(pairing.individual_time) + " minutes"
		attack_text += "\nCurrent Position: " + pairing.current_position_state
		
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
				var result_text = "Rolled: " + str(current_roll_result) + " (needed ≤" + str(pairing.dice_threshold) + ")\n"
				result_text += "Individual Stats: Cost " + str(pairing.individual_cost) + ", Time " + str(pairing.individual_time) + "\n"
				var success = current_roll_result <= pairing.dice_threshold
				result_text += "Result: " + ("SUCCESS!" if success else "FAILURE")
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
			
			update_roll_button_text()
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

func update_roll_button_text():
	"""Update the roll button text with remaining rolls"""
	if not roll_button or ui_state != "ready":
		return
		
	var base_text = roll_button.text
	var remaining_text = ""
	
	if rolls_remaining > 1:
		remaining_text = " (" + str(rolls_remaining) + " Remaining)"
	elif rolls_remaining == 1:
		remaining_text = " (Last Roll)"
	
	# Only add remaining text if it doesn't already contain it
	if not base_text.contains("("):
		roll_button.text = base_text + remaining_text

func _on_roll_button_pressed():
	"""Handle roll button press"""
	if is_rolling or discussion_mode or ui_state != "ready":
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
	
	rolling_results.append(result)
	current_roll_result = 0
	
	# Show result immediately
	ui_state = "result_shown"
	update_dice_result_text(pairing)
	update_roll_button_for_pairing(pairing)

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
	
	rolling_results.append(result)
	current_roll_result = 0
	
	# Show result immediately
	ui_state = "result_shown"
	update_dice_result_text(pairing)
	update_roll_button_for_pairing(pairing)

func perform_dice_roll(pairing: Dictionary):
	"""Perform actual dice roll with individual calculations"""
	if is_rolling or ui_state != "ready":
		return
	
	# Ensure dice starts in correct position
	force_dice_position()
	
	is_rolling = true
	ui_state = "rolling"
	update_roll_button_for_pairing(pairing)
	
	# Update text to show rolling state
	update_dice_result_text(pairing)
	
	# Generate result ONCE before animation
	var roll_result = randi_range(1, 10)
	current_roll_result = roll_result
	
	# Simple dice animation - NO random changes during animation
	await animate_dice_roll_simple(roll_result)
	
	var success = roll_result <= pairing.dice_threshold
	
	# Store result with individual card data
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
	
	rolling_results.append(result)
	
	# Update result indicator
	update_result_indicator(roll_result, pairing.dice_threshold)
	
	# Show result
	is_rolling = false
	ui_state = "result_shown"
	update_dice_result_text(pairing)
	update_roll_button_for_pairing(pairing)

func animate_dice_roll_simple(final_result: int) -> void:
	"""Simple dice animation - show final result then cup reveal"""
	# Set the dice to show the final result immediately
	set_dice_display_only(final_result)
	
	# Store original dice position before animation
	var original_dice_pos = dice_base_position
	
	# Brief pause to show the roll
	await get_tree().create_timer(0.5).timeout
	
	# Play cup reveal animation if available
	if animation_player and animation_player.has_animation("cup_reveal"):
		animation_player.play("cup_reveal")
		await animation_player.animation_finished
	
	# Force dice back to original position after animation
	if dice_sprite:
		dice_sprite.position = original_dice_pos

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
	
	# Color based on success/failure
	if roll_result <= threshold:
		result_indicator.color = Color.GREEN
	else:
		result_indicator.color = Color.RED

func show_manual_entry():
	"""Show manual entry controls (legacy - kept for compatibility)"""
	var manual_container = get_node_or_null("DialogPanel/DiceContainer/ManualContainer")
	if manual_container:
		manual_container.visible = true
	
	# Note: Moderator controls are now handled by the manual toggle directly

func _on_manual_toggle_pressed():
	"""Toggle moderator controls visibility"""
	if moderator_container:
		moderator_container.visible = !moderator_container.visible
		
		if moderator_container.visible:
			# Show description when controls are revealed
			if dice_result_label:
				dice_result_label.text = "Moderator Controls Available:\n🔴 Red Wins | 🔵 Blue Wins | ⏭️ Skip (No Effect)"
				dice_result_label.modulate = Color.YELLOW
		else:
			# Reset to normal display when controls are hidden
			if current_pairing_index < card_pairings.size():
				var pairing = card_pairings[current_pairing_index]
				update_dice_result_text(pairing)

func _on_manual_submit_pressed():
	"""Handle manual roll submission (if manual entry SpinBox is used)"""
	if current_pairing_index >= card_pairings.size() or not manual_entry:
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
	
	rolling_results.append(result)
	
	# Update display without changing position
	set_dice_display_only(manual_roll)
	update_result_indicator(manual_roll, pairing.dice_threshold)
	
	# Ensure dice position is correct after display update
	force_dice_position()
	
	# Hide manual controls
	var manual_container = get_node_or_null("DialogPanel/DiceContainer/ManualContainer")
	if manual_container:
		manual_container.visible = false
	if moderator_container:
		moderator_container.visible = false
	
	# Show result
	ui_state = "result_shown"
	update_dice_result_text(pairing)
	update_roll_button_for_pairing(pairing)

# Moderator control handlers
func _on_red_win_pressed():
	"""Handle moderator red team auto-win"""
	if current_pairing_index >= card_pairings.size():
		return
	
	var pairing = card_pairings[current_pairing_index]
	
	# Force success regardless of dice threshold
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
	
	rolling_results.append(result)
	
	# Update display
	set_dice_display_only(1)
	update_result_indicator(1, pairing.dice_threshold)
	force_dice_position()
	
	# Hide moderator controls after use
	if moderator_container:
		moderator_container.visible = false
	
	# Show result with special text
	ui_state = "result_shown"
	if dice_result_label:
		dice_result_label.text = "MODERATOR OVERRIDE: Red Team Wins!\nRoll: 1 (Perfect Success)"
		dice_result_label.modulate = Color.RED
	update_roll_button_for_pairing(pairing)

func _on_blue_win_pressed():
	"""Handle moderator blue team auto-win"""
	if current_pairing_index >= card_pairings.size():
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
	
	rolling_results.append(result)
	
	# Update display
	set_dice_display_only(10)
	update_result_indicator(10, pairing.dice_threshold)
	force_dice_position()
	
	# Hide moderator controls after use
	if moderator_container:
		moderator_container.visible = false
	
	# Show result with special text
	ui_state = "result_shown"
	if dice_result_label:
		dice_result_label.text = "MODERATOR OVERRIDE: Blue Team Wins!\nRoll: 10 (Complete Failure)"
		dice_result_label.modulate = Color.BLUE
	update_roll_button_for_pairing(pairing)

func _on_skip_pressed():
	"""Handle moderator skip (no result)"""
	if current_pairing_index >= card_pairings.size():
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
	
	rolling_results.append(result)
	current_roll_result = 0
	
	# Hide moderator controls after use
	if moderator_container:
		moderator_container.visible = false
	
	# Show result with special text
	ui_state = "result_shown"
	if dice_result_label:
		dice_result_label.text = "MODERATOR OVERRIDE: Skipped\nNo effect on game state"
		dice_result_label.modulate = Color.GRAY
	update_roll_button_for_pairing(pairing)

func _on_continue_button_pressed():
	"""Handle continue button press - user-controlled flow"""
	if ui_state == "result_shown":
		advance_to_next_pairing()
	elif discussion_mode:
		complete_all_rolls()

func advance_to_next_pairing():
	"""Advance to the next card pairing or complete"""
	current_pairing_index += 1
	rolls_remaining -= 1
	
	if current_pairing_index >= card_pairings.size():
		show_discussion_time()
	else:
		# Reset UI for next roll
		if result_indicator:
			result_indicator.visible = false
		if moderator_container:
			moderator_container.visible = false
		
		ui_state = "ready"
		current_roll_result = 0
		
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
			var override_type = result.moderator_override
			if override_type == "RED_WIN":
				summary_text += "[color=red]Result: MODERATOR OVERRIDE - RED WINS[/color]\n"
			elif override_type == "BLUE_WIN":
				summary_text += "[color=blue]Result: MODERATOR OVERRIDE - BLUE WINS[/color]\n"
			elif override_type == "MANUAL_ENTRY":
				var success_text = "SUCCESS" if result.success else "FAILURE"
				var color = "green" if result.success else "red"
				summary_text += "Manual Roll: " + str(result.roll_result) + "/10 (needed ≤" + str(result.dice_threshold) + ")\n"
				summary_text += "[color=" + color + "]Result: MANUAL " + success_text + "[/color]\n"
		else:
			var success_text = "SUCCESS" if result.success else "FAILURE"
			var color = "green" if result.success else "red"
			summary_text += "Roll: " + str(result.roll_result) + "/10 (needed ≤" + str(result.dice_threshold) + ")\n"
			summary_text += "[color=" + color + "]Result: " + success_text + "[/color]\n"
		
		if i < rolling_results.size() - 1:
			summary_text += "\n"
	
	# Position states before
	summary_text += "\n\n[b][font_size=20]Position States[/font_size][/b]\n\n"
	
	# Combine current state and projected changes on same line
	for i in range(3):
		var current_state = "EMPTY"  # Default
		if GameData and GameData.has_method("get_position_states_snapshot"):
			var position_states = GameData.get_position_states_snapshot()
			if i < position_states.size():
				current_state = position_states[i].state
		
		# Pad current state to consistent width for alignment
		var padded_state = current_state.rpad(6)  # Pad to 6 characters (longest is "EMPTY ")
		
		# Find projected change for this position
		var projected_change = "[color=gray]No attack[/color]"
		for result in rolling_results:
			if result.attack_index == i:
				if result.get("skipped", false):
					projected_change = "[color=gray]→ Skipped[/color]"
				elif result.success:
					projected_change = "[color=yellow]→ Advance[/color]"
				else:
					projected_change = "[color=gray]→ No change[/color]"
				break
		
		summary_text += "Position " + str(i + 1) + ": " + padded_state + " " + projected_change + "\n"
	
	# Red team victory condition
	summary_text += "\n[b][font_size=20]Victory Condition[/font_size][/b]\n"
	summary_text += "[color=red]When ANY position reaches E/E[/color]\n"
	summary_text += "[color=blue]Preventing this until time expires[/color]\n"
	
	round_summary_label.text = summary_text

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
