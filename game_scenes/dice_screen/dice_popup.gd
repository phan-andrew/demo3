extends Control

# Signals for communication with main game
signal dice_completed(result: int, success: bool)
signal dice_cancelled

# Dice system variables
var current_roll_result: int = 0
var success_threshold: int = 5
var rolls_remaining: int = 3
var is_rolling: bool = false
var is_manual_mode: bool = false

# Animation and timing
var roll_duration: float = 2.0
var cup_lift_delay: float = 1.5
var result_display_delay: float = 0.5

# UI References - Updated to match actual scene structure
@onready var dice_sprite: AnimatedSprite2D = $Panel/DiceContainer/DiceSprite
@onready var dice_number_label: Label = $Panel/DiceContainer/DiceSprite/NumberLabel
@onready var cup_sprite: Sprite2D = $Panel/DiceContainer/CupSprite
@onready var background_sprite: TextureRect = $UnderwaterDiceScene2  # Updated reference
@onready var dice_result_label: Label = $Panel/DiceContainer/DiceResult
@onready var roll_button: Button = $Panel/DiceContainer/ButtonContainer/RollButton
@onready var manual_toggle: Button = $Panel/DiceContainer/ButtonContainer/ManualToggle
@onready var manual_entry: SpinBox = $Panel/DiceContainer/ManualEntry
@onready var manual_submit: Button = $Panel/DiceContainer/ManualSubmit
@onready var close_button: Button = $Panel/HeaderContainer/CloseButton
@onready var admin_button: Button = $Panel/HeaderContainer/AdminButton

# Info display
@onready var attack_info: RichTextLabel = $Panel/InfoContainer/AttackInfo
@onready var defense_info: RichTextLabel = $Panel/InfoContainer/DefenseInfo
@onready var strength_info: Label = $Panel/StrengthContainer/StrengthInfo
@onready var red_section: ColorRect = $Panel/StrengthContainer/StrengthBar/RedSection
@onready var blue_section: ColorRect = $Panel/StrengthContainer/StrengthBar/BlueSection
@onready var result_indicator: ColorRect = $Panel/StrengthContainer/StrengthBar/ResultIndicator

# Animation effects
var roll_tween: Tween
var shake_intensity: float = 5.0

func _ready():
	# Wait a frame for all nodes to be ready
	await get_tree().process_frame
	
	setup_ui()
	load_dice_assets()
	setup_strength_display()
	display_current_situation()
	connect_signals()

func setup_ui():
	"""Initialize UI components and layout"""
	# Set up the main panel
	var panel = $Panel
	panel.custom_minimum_size = Vector2(700, 500)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# Initial button states
	if manual_entry:
		manual_entry.visible = false
	if manual_submit:
		manual_submit.visible = false
	update_roll_button_text()

func load_dice_assets():
	"""Load dice and cup sprite assets"""
	
	# Load the single dice image - check if it exists first
	var dice_path = "res://game_scenes/dice_screen/Dice.png"
	if ResourceLoader.exists(dice_path) and dice_sprite:
		var dice_texture = load(dice_path)
		# Since it's an AnimatedSprite2D, we need to create SpriteFrames
		if not dice_sprite.sprite_frames:
			dice_sprite.sprite_frames = SpriteFrames.new()
			dice_sprite.sprite_frames.add_animation("default")
			dice_sprite.sprite_frames.add_frame("default", dice_texture)
		dice_sprite.scale = Vector2(4, 4)  # Scale up for visibility
		dice_sprite.play("default")
	else:
		print("Warning: Dice.png not found at ", dice_path, " or dice_sprite is null")
	
	# Load the cup image
	var cup_path = "res://game_scenes/dice_screen/Cup.png"
	if ResourceLoader.exists(cup_path) and cup_sprite:
		cup_sprite.texture = load(cup_path)
		cup_sprite.scale = Vector2(4, 4)  # Scale up for visibility
		cup_sprite.z_index = 1  # Above dice
	else:
		print("Warning: Cup.png not found at ", cup_path, " or cup_sprite is null")
	
	# Load themed background based on current settings
	load_themed_background()
	
	# Initially hide the number label
	if dice_number_label:
		dice_number_label.visible = false

func load_themed_background():
	"""Load the appropriate background based on current theme"""
	var theme_index = 0  # Default to underwater
	
	# Get current theme from Settings
	if has_node("/root/Settings"):
		var settings = get_node("/root/Settings")
		theme_index = settings.theme
	
	var bg_path = ""
	match theme_index:
		0:  # Underwater
			bg_path = "res://game_scenes/dice_screen/UnderwaterDiceScene.png"
		1:  # Air
			bg_path = "res://game_scenes/dice_screen/AirDiceScene.png"
		2:  # Surface/Land
			bg_path = "res://game_scenes/dice_screen/SurfaceDiceScene.png"
	
	# Try to load the themed background
	if ResourceLoader.exists(bg_path) and background_sprite:
		background_sprite.texture = load(bg_path)
		print("Loaded themed background: ", bg_path)
	else:
		print("Themed background not found: ", bg_path, " - using default")

func setup_strength_display():
	"""Setup the team strength visualization bar"""
	if not has_node("/root/GameData"):
		print("GameData not found, using default values")
		return
		
	var game_data = get_node("/root/GameData")
	var red_weight = game_data.red_team_weight
	var blue_weight = game_data.blue_team_weight
	var total_weight = red_weight + blue_weight
	
	if total_weight == 0:
		total_weight = 2  # Fallback
		red_weight = 1
		blue_weight = 1
	
	# Calculate bar sections
	var bar_width = 400
	var red_width = (red_weight / float(total_weight)) * bar_width
	var blue_width = bar_width - red_width
	
	if red_section:
		red_section.size.x = red_width
	if blue_section:
		blue_section.position.x = red_width
		blue_section.size.x = blue_width
	
	# Success threshold indicator
	success_threshold = game_data.get_dice_success_threshold()
	var threshold_position = (success_threshold / 10.0) * bar_width
	if result_indicator:
		result_indicator.position.x = threshold_position - 2
		result_indicator.size = Vector2(4, 30)
		result_indicator.color = Color.WHITE

func display_current_situation():
	"""Display current attack and defense information"""
	if not has_node("/root/GameData"):
		if attack_info:
			attack_info.text = "[b]Current Attack:[/b]\nGameData not available"
		if defense_info:
			defense_info.text = "[b]Active Defenses:[/b]\nGameData not available"
		return
	
	var game_data = get_node("/root/GameData")
	
	# Display attack info
	var attack_info_text = "[b]Current Attack:[/b]\n"
	var attack_info_dict = game_data.get_current_attack_info()
	if attack_info_dict.names.size() > 0:
		attack_info_text += attack_info_dict.combined_name + "\n"
		attack_info_text += "Cost: " + str(attack_info_dict.cost) + " | Time: " + str(attack_info_dict.time)
	else:
		attack_info_text += "No attacks selected"
	
	if attack_info:
		attack_info.text = attack_info_text
	
	# Display defense info
	var defense_info_text = "[b]Active Defenses:[/b]\n"
	var defense_list = game_data.get_current_defense_info()
	if defense_list.size() > 0:
		for defense in defense_list:
			defense_info_text += "• " + defense.name + " (Maturity: " + str(defense.maturity) + ")\n"
	else:
		defense_info_text += "No defenses active"
	
	if defense_info:
		defense_info.text = defense_info_text
	
	# Display success information
	var success_rate = game_data.get_attack_success_rate()
	if strength_info:
		strength_info.text = "Success Rate: " + str(int(success_rate * 100)) + "% | Roll " + str(success_threshold) + " or lower to succeed"

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

func _on_roll_button_pressed():
	"""Handle dice roll button press"""
	if is_rolling or rolls_remaining <= 0:
		return
	
	is_rolling = true
	if roll_button:
		roll_button.disabled = true
	if manual_toggle:
		manual_toggle.disabled = true
	
	await perform_dice_roll()
	
	rolls_remaining -= 1
	update_roll_button_text()
	
	if rolls_remaining <= 0:
		# Force completion after max rolls
		await get_tree().create_timer(1.0).timeout
		complete_dice_roll()
	else:
		if roll_button:
			roll_button.disabled = false
		if manual_toggle:
			manual_toggle.disabled = false
		is_rolling = false

func perform_dice_roll():
	"""Perform the animated dice roll sequence"""
	# Step 1: Cup covers dice
	if cup_sprite:
		cup_sprite.visible = true
	if dice_number_label:
		dice_number_label.visible = false
	if dice_result_label:
		dice_result_label.text = "Rolling..."
	
	await get_tree().create_timer(0.5).timeout
	
	# Step 2: Shake effect while rolling
	if dice_sprite:
		roll_tween = create_tween()
		roll_tween.set_loops()
		
		# Shake the dice under the cup
		var original_pos = dice_sprite.position
		for i in range(int(roll_duration * 10)):  # 10 shakes per second
			var shake_x = randf_range(-shake_intensity, shake_intensity)
			var shake_y = randf_range(-shake_intensity, shake_intensity)
			roll_tween.tween_property(dice_sprite, "position", original_pos + Vector2(shake_x, shake_y), 0.1)
			await get_tree().create_timer(0.1).timeout
		
		# Stop shaking and return to center
		if roll_tween:
			roll_tween.kill()
		dice_sprite.position = original_pos  # Reset to original position
	
	# Step 3: Determine result
	current_roll_result = randi_range(1, 10)
	
	await get_tree().create_timer(cup_lift_delay).timeout
	
	# Step 4: Cup disappears to reveal result
	if cup_sprite:
		var cup_tween = create_tween()
		cup_tween.tween_property(cup_sprite, "modulate:a", 0.0, 0.5)
		await cup_tween.finished
		cup_sprite.visible = false
		cup_sprite.modulate.a = 1.0  # Reset for next time
	
	await get_tree().create_timer(result_display_delay).timeout
	
	# Step 5: Show number on dice and display result
	if dice_number_label:
		dice_number_label.text = str(current_roll_result)
		dice_number_label.visible = true
	
	var is_success = current_roll_result <= success_threshold
	var result_color = Color.GREEN if is_success else Color.RED
	if dice_result_label:
		dice_result_label.text = "Rolled: " + str(current_roll_result) + " - " + ("SUCCESS!" if is_success else "FAILURE!")
		dice_result_label.modulate = result_color
	
	# Update strength bar with result indicator
	if result_indicator:
		var result_position = (current_roll_result / 10.0) * 400
		result_indicator.position.x = result_position - 2
		result_indicator.color = result_color

func complete_dice_roll():
	"""Complete the dice rolling process"""
	var is_success = current_roll_result <= success_threshold
	emit_signal("dice_completed", current_roll_result, is_success)

func _on_manual_toggle_pressed():
	"""Toggle manual entry mode"""
	is_manual_mode = !is_manual_mode
	
	if is_manual_mode:
		if manual_entry:
			manual_entry.visible = true
		if manual_submit:
			manual_submit.visible = true
		if roll_button:
			roll_button.visible = false
		if manual_toggle:
			manual_toggle.text = "Use Dice"
		if dice_result_label:
			dice_result_label.text = "Enter manual result (1-10):"
	else:
		if manual_entry:
			manual_entry.visible = false
		if manual_submit:
			manual_submit.visible = false
		if roll_button:
			roll_button.visible = true
		if manual_toggle:
			manual_toggle.text = "Manual Entry"
		if dice_result_label:
			dice_result_label.text = "Ready to roll..."

func _on_manual_submit_pressed():
	"""Handle manual entry submission"""
	if manual_entry:
		current_roll_result = int(manual_entry.value)
	var is_success = current_roll_result <= success_threshold
	
	# Show the number on the dice
	if dice_number_label:
		dice_number_label.text = str(current_roll_result)
		dice_number_label.visible = true
	if cup_sprite:
		cup_sprite.visible = false
	
	if dice_result_label:
		dice_result_label.text = "Manual: " + str(current_roll_result) + " - " + ("SUCCESS!" if is_success else "FAILURE!")
		dice_result_label.modulate = Color.GREEN if is_success else Color.RED
	
	await get_tree().create_timer(1.0).timeout
	complete_dice_roll()

func _on_admin_button_pressed():
	"""Admin override for testing"""
	if OS.is_debug_build():
		current_roll_result = success_threshold  # Force success
		complete_dice_roll()

func _on_close_button_pressed():
	"""Handle popup cancellation"""
	emit_signal("dice_cancelled")

func update_roll_button_text():
	"""Update roll button text with remaining rolls"""
	if not roll_button:
		return
		
	if rolls_remaining > 0:
		roll_button.text = "Roll Dice (" + str(rolls_remaining) + " Remaining)"
		roll_button.disabled = false
	else:
		roll_button.text = "Max Rolls Used"
		roll_button.disabled = true

func _input(event):
	"""Handle input events"""
	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
