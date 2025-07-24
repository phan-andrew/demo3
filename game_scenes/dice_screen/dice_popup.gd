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
var cup_lift_delay: float = 1.0
var result_display_delay: float = 0.5

# UI References - Updated to match CenterContainer structure
@onready var dice_sprite: AnimatedSprite2D = $CenterContainer/Panel/DiceContainer/DiceArea/DiceSprite
@onready var dice_number_label: Label = $CenterContainer/Panel/DiceContainer/DiceArea/DiceSprite/NumberLabel
@onready var cup_sprite: Sprite2D = $CenterContainer/Panel/DiceContainer/DiceArea/CupSprite
@onready var animation_player: AnimationPlayer = $CenterContainer/Panel/DiceContainer/DiceArea/AnimationPlayer
@onready var background_sprite: TextureRect = $BackgroundLayer/UnderwaterDiceScene2
@onready var dice_result_label: Label = $CenterContainer/Panel/DiceContainer/DiceResult
@onready var roll_button: Button = $CenterContainer/Panel/DiceContainer/ButtonContainer/RollButton
@onready var manual_toggle: Button = $CenterContainer/Panel/DiceContainer/ButtonContainer/ManualToggle
@onready var manual_entry: SpinBox = $CenterContainer/Panel/DiceContainer/ManualEntry
@onready var manual_submit: Button = $CenterContainer/Panel/DiceContainer/ManualSubmit
@onready var close_button: Button = $CenterContainer/Panel/HeaderContainer/CloseButton
@onready var admin_button: Button = $CenterContainer/Panel/HeaderContainer/AdminButton

# Info display
@onready var attack_info: RichTextLabel = $CenterContainer/Panel/InfoContainer/AttackInfo
@onready var defense_info: RichTextLabel = $CenterContainer/Panel/InfoContainer/DefenseInfo
@onready var strength_info: Label = $CenterContainer/Panel/StrengthContainer/StrengthInfo
@onready var red_section: ColorRect = $CenterContainer/Panel/StrengthContainer/StrengthBar/RedSection
@onready var blue_section: ColorRect = $CenterContainer/Panel/StrengthContainer/StrengthBar/BlueSection
@onready var result_indicator: ColorRect = $CenterContainer/Panel/StrengthContainer/StrengthBar/ResultIndicator

# Animation effects
var roll_tween: Tween
var shake_intensity: float = 10.0
var dice_original_position: Vector2
var cup_original_position: Vector2

func _ready():
	# Wait a frame for all nodes to be ready
	await get_tree().process_frame
	
	print("Dice popup initializing...")
	setup_initial_state()
	load_dice_assets()
	setup_strength_display()
	display_current_situation()
	connect_signals()
	print("Dice popup ready!")

func setup_initial_state():
	"""Initialize the dice popup visual state"""
	# Store original positions
	if dice_sprite:
		dice_original_position = dice_sprite.position
		print("Dice original position: ", dice_original_position)
	
	if cup_sprite:
		cup_original_position = cup_sprite.position
		cup_sprite.visible = false  # Start hidden, will show during roll
		print("Cup original position: ", cup_original_position)
	
	# Hide dice number initially
	if dice_number_label:
		dice_number_label.visible = false
	
	# Set up manual entry
	if manual_entry:
		manual_entry.visible = false
	if manual_submit:
		manual_submit.visible = false
	
	update_roll_button_text()

func load_dice_assets():
	"""Load dice and cup sprite assets"""
	print("Loading dice assets...")
	
	# First, try to load and set the background
	load_themed_background()
	
	# Load the dice image
	var dice_path = "res://game_scenes/dice_screen/Dice.png"
	if ResourceLoader.exists(dice_path) and dice_sprite:
		var dice_texture = load(dice_path)
		if dice_texture:
			# Create SpriteFrames for AnimatedSprite2D
			if not dice_sprite.sprite_frames:
				dice_sprite.sprite_frames = SpriteFrames.new()
			dice_sprite.sprite_frames.clear_all()
			dice_sprite.sprite_frames.add_animation("default")
			dice_sprite.sprite_frames.add_frame("default", dice_texture)
			dice_sprite.play("default")
			print("Dice texture loaded successfully")
		else:
			print("Failed to load dice texture")
			create_fallback_dice()
	else:
		print("Dice.png not found, creating fallback")
		create_fallback_dice()
	
	# Load the cup image
	var cup_path = "res://game_scenes/dice_screen/Cup.png"
	if ResourceLoader.exists(cup_path) and cup_sprite:
		var cup_texture = load(cup_path)
		if cup_texture:
			cup_sprite.texture = cup_texture
			print("Cup texture loaded successfully")
		else:
			print("Failed to load cup texture")
			create_fallback_cup()
	else:
		print("Cup.png not found, creating fallback")
		create_fallback_cup()

func create_fallback_dice():
	"""Create a simple colored square as dice fallback"""
	var fallback_texture = ImageTexture.new()
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	image.fill(Color.WHITE)
	# Add a black border
	for x in range(64):
		for y in range(64):
			if x < 3 or x > 60 or y < 3 or y > 60:
				image.set_pixel(x, y, Color.BLACK)
	fallback_texture.set_image(image)
	
	if not dice_sprite.sprite_frames:
		dice_sprite.sprite_frames = SpriteFrames.new()
	dice_sprite.sprite_frames.clear_all()
	dice_sprite.sprite_frames.add_animation("default")
	dice_sprite.sprite_frames.add_frame("default", fallback_texture)
	dice_sprite.play("default")
	print("Using fallback dice texture")

func create_fallback_cup():
	"""Create a simple colored rectangle as cup fallback"""
	var fallback_texture = ImageTexture.new()
	var image = Image.create(80, 100, false, Image.FORMAT_RGB8)
	image.fill(Color(0.6, 0.4, 0.2))  # Brown color
	# Add darker edges for definition
	for x in range(80):
		for y in range(100):
			if x < 3 or x > 76 or y < 3 or y > 96:
				image.set_pixel(x, y, Color(0.4, 0.2, 0.1))
	fallback_texture.set_image(image)
	cup_sprite.texture = fallback_texture
	print("Using fallback cup texture")

func load_themed_background():
	"""Load the appropriate background based on current theme"""
	print("Loading themed background...")
	
	var theme_index = 0  # Default to underwater
	
	# Get current theme from Settings
	if has_node("/root/Settings"):
		var settings = get_node("/root/Settings")
		theme_index = settings.theme
		print("Current theme index: ", theme_index)
	
	var bg_path = ""
	match theme_index:
		0:  # Underwater
			bg_path = "res://game_scenes/dice_screen/UnderwaterDiceScene.png"
		1:  # Air
			bg_path = "res://game_scenes/dice_screen/AirDiceScene.png"
		2:  # Surface/Land
			bg_path = "res://game_scenes/dice_screen/SurfaceDiceScene.png"
	
	print("Attempting to load background: ", bg_path)
	
	# Try to load and set the background
	if ResourceLoader.exists(bg_path):
		var bg_texture = load(bg_path)
		if bg_texture and background_sprite:
			background_sprite.texture = bg_texture
			print("Background loaded successfully: ", bg_path)
		else:
			print("Failed to load background texture or background_sprite is null")
			create_fallback_background()
	else:
		print("Background file not found: ", bg_path)
		create_fallback_background()

func create_fallback_background():
	"""Create a simple gradient background as fallback"""
	print("Creating fallback background...")
	if background_sprite:
		var fallback_texture = ImageTexture.new()
		var image = Image.create(256, 256, false, Image.FORMAT_RGB8)
		
		# Create a simple blue gradient (underwater theme)
		for y in range(256):
			var blue_intensity = 0.2 + (y / 256.0) * 0.6  # Darker at top, lighter at bottom
			var color = Color(0.1, 0.3, blue_intensity)
			for x in range(256):
				image.set_pixel(x, y, color)
		
		fallback_texture.set_image(image)
		background_sprite.texture = fallback_texture
		print("Fallback background created")

func setup_strength_display():
	"""Setup the team strength visualization bar"""
	if not has_node("/root/GameData"):
		print("GameData not found, using default values")
		success_threshold = 5
		if strength_info:
			strength_info.text = "Success Rate: 50% | Roll 5 or lower to succeed"
		return
		
	var game_data = get_node("/root/GameData")
	var red_weight = game_data.red_team_weight
	var blue_weight = game_data.blue_team_weight
	var total_weight = red_weight + blue_weight
	
	if total_weight == 0:
		total_weight = 2
		red_weight = 1
		blue_weight = 1
	
	# Calculate bar sections (now 500px wide)
	var bar_width = 500
	var red_width = (red_weight / float(total_weight)) * bar_width
	var blue_width = bar_width - red_width
	
	if red_section:
		red_section.size.x = red_width
	if blue_section:
		blue_section.position.x = red_width
		blue_section.size.x = blue_width
	
	# Success threshold
	success_threshold = game_data.get_dice_success_threshold()
	var threshold_position = (success_threshold / 10.0) * bar_width
	if result_indicator:
		result_indicator.position.x = threshold_position - 2
		result_indicator.size = Vector2(4, 40)
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
	
	print("Starting dice roll...")
	is_rolling = true
	if roll_button:
		roll_button.disabled = true
	if manual_toggle:
		manual_toggle.disabled = true
	
	await perform_dice_roll()
	
	rolls_remaining -= 1
	update_roll_button_text()
	
	if rolls_remaining <= 0:
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
	print("Performing dice roll animation...")
	
	# Step 1: Show cup covering dice
	if cup_sprite:
		cup_sprite.position = cup_original_position
		cup_sprite.visible = true
		cup_sprite.modulate.a = 1.0
		cup_sprite.z_index = 3  # Above dice
		print("Cup shown at position: ", cup_sprite.position)
	
	if dice_number_label:
		dice_number_label.visible = false
	
	if dice_result_label:
		dice_result_label.text = "🎲 Rolling dice..."
		dice_result_label.modulate = Color.WHITE
	
	await get_tree().create_timer(0.5).timeout
	
	# Step 2: Shake effect while rolling
	if dice_sprite:
		roll_tween = create_tween()
		roll_tween.set_loops(int(roll_duration * 3))  # 3 shakes per second
		
		for i in range(int(roll_duration * 3)):
			var shake_x = randf_range(-shake_intensity, shake_intensity)
			var shake_y = randf_range(-shake_intensity, shake_intensity)
			var target_pos = dice_original_position + Vector2(shake_x, shake_y)
			roll_tween.tween_property(dice_sprite, "position", target_pos, 0.33)
			await get_tree().create_timer(0.33).timeout
		
		# Return to original position
		dice_sprite.position = dice_original_position
		if roll_tween:
			roll_tween.kill()
	
	# Step 3: Determine result
	current_roll_result = randi_range(1, 10)
	print("Dice rolled: ", current_roll_result)
	
	await get_tree().create_timer(cup_lift_delay).timeout
	
	# Step 4: Use AnimationPlayer for cup reveal if available, otherwise manual tween
	if animation_player and animation_player.has_animation("cup_reveal"):
		print("Using AnimationPlayer for cup reveal")
		animation_player.play("cup_reveal")
		await animation_player.animation_finished
	else:
		print("Using manual tween for cup reveal")
		# Manual cup removal animation
		if cup_sprite:
			var cup_tween = create_tween()
			cup_tween.parallel().tween_property(cup_sprite, "position", cup_original_position + Vector2(-50, -120), 1.5)
			cup_tween.parallel().tween_property(cup_sprite, "rotation", 0.35, 1.5)
			cup_tween.parallel().tween_property(cup_sprite, "modulate:a", 0.0, 1.5)
			await cup_tween.finished
	
	# Ensure cup is hidden
	if cup_sprite:
		cup_sprite.visible = false
		cup_sprite.modulate.a = 1.0
		cup_sprite.position = cup_original_position
		cup_sprite.rotation = 0.0
	
	await get_tree().create_timer(result_display_delay).timeout
	
	# Step 5: Show result
	if dice_number_label:
		dice_number_label.text = str(current_roll_result)
		dice_number_label.visible = true
	
	var is_success = current_roll_result <= success_threshold
	var result_color = Color.GREEN if is_success else Color.RED
	
	if dice_result_label:
		var result_text = "🎲 Rolled: " + str(current_roll_result) + " - "
		result_text += "✅ SUCCESS!" if is_success else "❌ FAILURE!"
		dice_result_label.text = result_text
		dice_result_label.modulate = result_color
	
	# Update strength bar with result indicator (500px wide now)
	if result_indicator:
		var result_position = (current_roll_result / 10.0) * 500
		result_indicator.position.x = result_position - 2
		result_indicator.color = result_color
	
	print("Dice roll animation completed - Result: ", current_roll_result, " Success: ", is_success)

func complete_dice_roll():
	"""Complete the dice rolling process"""
	var is_success = current_roll_result <= success_threshold
	print("Completing dice roll - Result: ", current_roll_result, " Success: ", is_success)
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
			manual_toggle.text = "🎲 Use Dice"
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
			manual_toggle.text = "✏️ Manual Entry"
		if dice_result_label:
			dice_result_label.text = "Ready to roll the dice..."

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
		var result_text = "✏️ Manual: " + str(current_roll_result) + " - "
		result_text += "✅ SUCCESS!" if is_success else "❌ FAILURE!"
		dice_result_label.text = result_text
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
	print("Dice popup cancelled")
	emit_signal("dice_cancelled")

func update_roll_button_text():
	"""Update roll button text with remaining rolls"""
	if not roll_button:
		return
		
	if rolls_remaining > 0:
		roll_button.text = "🎲 Roll Dice (" + str(rolls_remaining) + " Remaining)"
		roll_button.disabled = false
	else:
		roll_button.text = "🎲 Max Rolls Used"
		roll_button.disabled = true

func _input(event):
	"""Handle input events"""
	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()
