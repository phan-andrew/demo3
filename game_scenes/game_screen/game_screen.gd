extends Node2D

# Enhanced game_screen.gd - Connected Attack Chain System Integration

# Core game references
var aCards = []
var dCards = []
var attackbuttons = []
var defendbuttons = []
var timers = []

# Game state variables
var save_path = OS.get_user_data_dir() + "/seacat_connected_game_data.csv"
var currenttimer = 0
var timeTaken = 0
var game_won = false

# Connected attack chain system variables
var current_roll_results = []
var progress_bar_sprite = null  # Single progress bar sprite
var victory_overlay = null  # Victory screen overlay

# UI icons
var playIcon = preload("res://images/UI_images/play_button.png")
var pauseIcon = preload("res://images/UI_images/pause_button.png")

# Enhanced dice system
var use_dice_system = true
var dice_popup_scene = preload("res://game_scenes/dice_screen/dice_popup.tscn")
var active_dice_popup = null

# Round tracking
var round_number = 1

# Progress bar images
var progress_bar_images = [
	"res://images/bar/0.png",  # Empty
	"res://images/bar/1.png",  # IA filled
	"res://images/bar/2.png",  # PEP filled
	"res://images/bar/3.png"   # E/E filled
]

# Font resource
var kongtext_font = preload("res://pixel font/kongtext.ttf")
var round_info_popup_scene = preload("res://game_scenes/round_info_popup/RoundInfoPopup.tscn")


func _ready():
	initialize_connected_game()
	setup_connections()

func initialize_connected_game():
	"""Initialize the game with connected attack chain system"""
	# Test file system access first
	test_file_system_access()
	
	# Initialize card arrays with null checks
	aCards = []
	dCards = []
	
	# Safely get attack cards
	for i in range(1, 4):
		var card_node = get_node_or_null("a_" + str(i))
		if card_node:
			aCards.append(card_node)
			card_node.cardType = "a"
			var card_back = card_node.get_node_or_null("card/card_back")
			if card_back:
				card_back.frame = 4
		else:
			print("Warning: Attack card a_", i, " not found")
	
	# Safely get defense cards
	for i in range(1, 4):
		var card_node = get_node_or_null("d_" + str(i))
		if card_node:
			dCards.append(card_node)
			card_node.cardType = "d"
			var card_back = card_node.get_node_or_null("card/card_back")
			if card_back:
				card_back.frame = 3
		else:
			print("Warning: Defense card d_", i, " not found")
	
	# Setup button arrays
	setup_button_arrays()
	
	# Connect dropdown to card arrays
	var dropdown = get_node_or_null("dropdown")
	if dropdown and dropdown.has_method("set_card_references"):
		dropdown.set_card_references(aCards, dCards)
	
	# Initialize timers
	setup_timers()
	
	# Initial states
	disable_attack_buttons(true)
	disable_defend_buttons(true)
	
	var window = get_node_or_null("Window")
	if window:
		window.visible = false
	var end_game = get_node_or_null("EndGame")
	if end_game:
		end_game.visible = false
	
	currenttimer = 0
	
	# Setup enhanced save file for connected system
	setup_connected_save_file()
	
	# Setup single progress bar UI
	setup_single_progress_bar()
	
	# Initialize GameData connected attack chains
	if GameData:
		GameData.reset_attack_chains()
		print("=== CONNECTED ATTACK CHAIN SYSTEM INITIALIZED ===")
		print("Round: ", round_number)
		GameData.debug_show_game_state()
	
	# Start background music
	if has_node("/root/Music"):
		var music = get_node("/root/Music")
		if music.has_method("play_music"):
			music.play_music()

func test_file_system_access():
	"""Test if we can write files to the user data directory"""
	print("=== TESTING FILE SYSTEM ACCESS ===")
	print("User data directory: ", OS.get_user_data_dir())
	
	var test_path = OS.get_user_data_dir() + "/seacat_write_test.txt"
	var test_file = FileAccess.open(test_path, FileAccess.WRITE)
	
	if test_file:
		test_file.store_string("File system write test successful at " + Time.get_time_string_from_system())
		test_file.close()
		print("✅ File system write test PASSED")
		
		# Test reading it back
		var read_file = FileAccess.open(test_path, FileAccess.READ)
		if read_file:
			var content = read_file.get_as_text()
			read_file.close()
			print("✅ File system read test PASSED: ", content.substr(0, 50), "...")
		else:
			print("❌ File system read test FAILED")
	else:
		print("❌ File system write test FAILED")
		print("❌ Error code: ", FileAccess.get_open_error())
		print("❌ This will prevent CSV data from being saved!")
	
	print("=== FILE SYSTEM TEST COMPLETE ===")

func setup_button_arrays():
	"""Setup attack and defense button arrays"""
	attackbuttons = []
	defendbuttons = []
	
	var attack_dropdown = get_node_or_null("dropdown/attack_option")
	var attack_submit = get_node_or_null("AttackSubmit")
	var defend_dropdown = get_node_or_null("dropdown/defend_option")
	var defend_submit = get_node_or_null("DefenseSubmit")
	
	if attack_dropdown:
		attackbuttons.append(attack_dropdown)
	if attack_submit:
		attackbuttons.append(attack_submit)
	if defend_dropdown:
		defendbuttons.append(defend_dropdown)
	if defend_submit:
		defendbuttons.append(defend_submit)

func setup_timers():
	"""Setup timer references and initial states"""
	timers = []
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	
	if timer1:
		timers.append(timer1)
		var pause_button = timer1.get_node_or_null("pause")
		if pause_button:
			pause_button.disabled = true
		
		# Initialize timer display
		if timer1.has_method("get") and timer1.initialTime != null:
			var initialTime = timer1.initialTime
			var minutes = int(initialTime) / 60
			var seconds = int(initialTime) % 60
			timer1.text = str(minutes) + (":%02d" % seconds)
	
	if timer2:
		timers.append(timer2)
		if timer2.has_method("get") and timer2.initialTime != null:
			var initialTime = timer2.initialTime
			var minutes = int(initialTime) / 60
			var seconds = int(initialTime) % 60
			timer2.text = str(minutes) + (":%02d" % seconds)

func setup_connections():
	"""Setup signal connections for connected attack chain system"""
	if GameData:
		# Connect attack chain signals
		if not GameData.dice_roll_completed_signal.is_connected(_on_dice_roll_completed):
			GameData.dice_roll_completed_signal.connect(_on_dice_roll_completed)
		if not GameData.attack_chain_victory.is_connected(_on_attack_chain_victory):
			GameData.attack_chain_victory.connect(_on_attack_chain_victory)
		if not GameData.timeline_victory.is_connected(_on_timeline_victory):
			GameData.timeline_victory.connect(_on_timeline_victory)
		# Connect discussion time signal for enhanced dice system
		if not GameData.discussion_time_needed.is_connected(_on_discussion_time_completed):
			GameData.discussion_time_needed.connect(_on_discussion_time_completed)

func setup_connected_save_file():
	"""Setup CSV with headers for connected attack chain tracking"""
	print("=== SETTING UP CSV FILE ===")
	print("Save path: ", save_path)
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var headers = [
			"Round", "Timestamp", "Position_1_Start", "Position_2_Start", "Position_3_Start",
			"Attack_1", "Attack_1_Cost", "Attack_1_Time", "Attack_1_Type", 
			"Attack_2", "Attack_2_Cost", "Attack_2_Time", "Attack_2_Type",
			"Attack_3", "Attack_3_Cost", "Attack_3_Time", "Attack_3_Type",
			"Defense_1", "Defense_1_Maturity", "Defense_1_Eviction",
			"Defense_2", "Defense_2_Maturity", "Defense_2_Eviction",
			"Defense_3", "Defense_3_Maturity", "Defense_3_Eviction",
			"Result_1", "Roll_1", "Success_1", "New_State_1",
			"Result_2", "Roll_2", "Success_2", "New_State_2",
			"Result_3", "Roll_3", "Success_3", "New_State_3",
			"Position_1_End", "Position_2_End", "Position_3_End",
			"Red_Victory", "Round_Notes"
		]
		file.store_csv_line(headers)
		file.close()
		print("✅ Connected attack chain save file initialized: ", save_path)
		
		# Test write a sample row to verify everything works
		test_csv_writing()
	else:
		print("❌ ERROR: Could not create CSV file: ", save_path)
		print("❌ Error code: ", FileAccess.get_open_error())
		print("❌ User data dir: ", OS.get_user_data_dir())

func test_csv_writing():
	"""Test CSV writing functionality"""
	print("=== TESTING CSV WRITING ===")
	
	var test_row = ["TEST", Time.get_time_string_from_system(), "Data", "Writing", "Test"]
	var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_csv_line(test_row)
		file.close()
		print("✅ Test row written successfully")
		
		# Read back to verify
		var verify_file = FileAccess.open(save_path, FileAccess.READ)
		if verify_file:
			var content = verify_file.get_as_text()
			verify_file.close()
			print("📄 File content preview (last 200 chars):")
			print(content.substr(max(0, content.length() - 200)))
		else:
			print("❌ Could not read back test file")
	else:
		print("❌ Could not write test row")
	
	print("=== CSV TEST COMPLETE ===")

func setup_single_progress_bar():
	"""Setup single progress bar UI element"""
	# Create progress bar sprite - 2.55x size (15% smaller than 3x)
	progress_bar_sprite = Sprite2D.new()
	progress_bar_sprite.name = "ProgressBarSprite"
	progress_bar_sprite.position = Vector2(576, 600)  # Lowered by 11 pixels
	progress_bar_sprite.scale = Vector2(2.55, 2.55)  # 15% smaller than 3x
	progress_bar_sprite.texture = load(progress_bar_images[0])  # Start with empty
	add_child(progress_bar_sprite)
	
	# Add explanation label with kongtext font - properly centered and lowered slightly
	var explanation_label = Label.new()
	explanation_label.name = "ProgressBarExplanation"
	explanation_label.text = "Red team wins when ANY position reaches E/E"
	explanation_label.position = Vector2(288, 630)  # Lowered slightly by 5 pixels
	explanation_label.size = Vector2(576, 25)  # Half screen width for proper centering
	explanation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explanation_label.add_theme_color_override("font_color", Color.WHITE)
	explanation_label.add_theme_font_override("font", kongtext_font)
	explanation_label.add_theme_font_size_override("font_size", 12)  # Reduced from 14 to 12
	add_child(explanation_label)

func _process(_delta):
	"""Main game loop"""
	handle_card_expansion_state()
	update_timer_display()
	update_theme_background()
	update_single_progress_bar()
	check_connected_game_end_conditions()
	
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

func handle_card_expansion_state():
	"""Handle card expansion logic to prevent multiple expansions"""
	var attack_expanded = false
	var defense_expanded = false
	
	for card in aCards:
		if card and card.expanded:
			attack_expanded = true
			break
	
	for card in dCards:
		if card and card.expanded:
			defense_expanded = true
			break
	
	# Disable other cards when one is expanded
	if attack_expanded:
		for card in aCards:
			if card and not card.expanded:
				if card.has_method("disable_expand"):
					card.disable_expand(true)
	else:
		for card in aCards:
			if card and card.inPlay:
				if card.has_method("disable_expand"):
					card.disable_expand(false)
				if card.has_method("disable_flip"):
					card.disable_flip(false)
	
	if defense_expanded:
		for card in dCards:
			if card and not card.expanded:
				if card.has_method("disable_expand"):
					card.disable_expand(true)
	else:
		for card in dCards:
			if card and card.inPlay:
				if card.has_method("disable_expand"):
					card.disable_expand(false)
				if card.has_method("disable_flip"):
					card.disable_flip(false)

func update_timer_display():
	"""Update timer display and pause button icon"""
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	
	if timer1 and timer1.play == true:
		currenttimer = 0
	elif timer2 and timer2.play == true:
		currenttimer = 1
	
	# Update pause button icon
	var pause_button = get_node_or_null("Timer_Label/pause")
	if pause_button:
		var timer1_playing = timer1 and timer1.play == true
		var timer2_playing = timer2 and timer2.play == true
		pause_button.icon = playIcon if not (timer1_playing or timer2_playing) else pauseIcon

func update_theme_background():
	"""Update background based on current theme"""
	var background = get_node_or_null("background")
	if background and has_node("/root/Settings"):
		var settings = get_node("/root/Settings")
		match settings.theme:
			0: background.texture = load("res://images/UI_images/progress_bar/underwater/water_background.png")
			1: background.texture = load("res://images/UI_images/progress_bar/air/Air Background.png")
			2: background.texture = load("res://images/UI_images/progress_bar/land/Land Background.png")

func update_single_progress_bar():
	"""Update single progress bar to show most advanced position"""
	if not GameData or not progress_bar_sprite:
		return
	
	# Get most advanced position progress directly from GameData
	var max_progress = GameData.get_most_advanced_position_progress()
	
	# Update progress bar sprite
	if max_progress < progress_bar_images.size():
		progress_bar_sprite.texture = load(progress_bar_images[max_progress])
		
		# Update explanation text color based on progress
		var explanation_label = get_node_or_null("ProgressBarExplanation")
		if explanation_label:
			match max_progress:
				0: explanation_label.modulate = Color.WHITE     # EMPTY
				1: explanation_label.modulate = Color.YELLOW    # IA
				2: explanation_label.modulate = Color.ORANGE    # PEP
				3: explanation_label.modulate = Color.RED       # E/E - Victory!

func check_connected_game_end_conditions():
	"""Check for connected game end conditions"""
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	var timeline = get_node_or_null("timeline")
	
	# Check timer expiration (Blue team victory)
	var timer1_expired = timer1 and timer1.initialTime <= 0
	var timer2_expired = timer2 and timer2.initialTime <= 0
	
	# Check timeline completion (Blue team victory)
	var timeline_completed = false
	if timeline:
		var current_round = timeline.current_round if timeline.has_method("get") else 0
		var round_end = timeline.round_end if timeline.has_method("get") else 100
		timeline_completed = current_round >= round_end
	
	# Connected attack chain victory handled by GameData signal
	
	if timer1_expired or timer2_expired or timeline_completed:
		handle_blue_team_victory("Time/Timeline completed")

func handle_red_team_victory(reason: String):
	"""Handle Red Team (connected attack chain) victory"""
	print("🔴 RED TEAM WINS: ", reason)
	game_won = true
	
	# Export final game data from both sources
	export_final_game_data("RED_TEAM_VICTORY")
	
	# Show red team victory screen
	show_victory_screen("🔴 RED TEAM VICTORY!", reason, Color.RED)

func handle_blue_team_victory(reason: String):
	"""Handle Blue Team (defense) victory"""
	print("🔵 BLUE TEAM WINS: ", reason)
	game_won = true
	
	# Export final game data from both sources  
	export_final_game_data("BLUE_TEAM_VICTORY")
	
	show_victory_screen("🔵 BLUE TEAM VICTORY!", reason, Color.BLUE)

func export_final_game_data(victory_type: String):
	"""Export final game data with comprehensive information"""
	print("=== EXPORTING FINAL GAME DATA ===")
	
	# Export from GameData if available
	if GameData and GameData.has_method("export_game_data_to_csv"):
		var gamedata_export = GameData.export_game_data_to_csv()
		var gamedata_path = OS.get_user_data_dir() + "/seacat_gamedata_final_export.csv"
		var gamedata_file = FileAccess.open(gamedata_path, FileAccess.WRITE)
		if gamedata_file:
			gamedata_file.store_string(gamedata_export)
			gamedata_file.close()
			print("✅ GameData final export saved to: ", gamedata_path)
		else:
			print("❌ Could not save GameData export")
	
	# Copy and finalize the main game CSV
	var main_file = FileAccess.open(save_path, FileAccess.READ)
	if main_file:
		var content = main_file.get_as_text()
		main_file.close()
		
		# Add victory information to the end
		content += "\n# GAME ENDED: " + victory_type + " at " + Time.get_time_string_from_system()
		content += "\n# Total Rounds: " + str(round_number - 1)
		
		var final_path = OS.get_user_data_dir() + "/seacat_final_game_complete.csv"
		var final_file = FileAccess.open(final_path, FileAccess.WRITE)
		if final_file:
			final_file.store_string(content)
			final_file.close()
			print("✅ Complete final game data saved to: ", final_path)
			print("📊 Final file size: ", content.length(), " characters")
		else:
			print("❌ Could not save complete final file")
	else:
		print("❌ Could not read main CSV file for final export")
	
	print("=== FINAL EXPORT COMPLETE ===")
	print("📁 Check these files:")
	print("  1. Live game data: ", save_path)
	print("  2. GameData export: ", OS.get_user_data_dir() + "/seacat_gamedata_final_export.csv")
	print("  3. Complete final: ", OS.get_user_data_dir() + "/seacat_final_game_complete.csv")

func show_victory_screen(title: String, reason: String, color: Color):
	"""Show victory screen with team colors, proper centering, and kongtext font"""
	# Remove any existing victory overlay
	if victory_overlay:
		victory_overlay.queue_free()
		victory_overlay = null
	
	# Create full-screen victory overlay
	victory_overlay = Control.new()
	victory_overlay.name = "VictoryOverlay"
	victory_overlay.anchors_preset = Control.PRESET_FULL_RECT
	victory_overlay.z_index = 1000  # Ensure it's on top
	add_child(victory_overlay)
	
	# Semi-transparent background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
	background.anchors_preset = Control.PRESET_FULL_RECT
	victory_overlay.add_child(background)
	
	# Main victory panel - centered
	var victory_panel = Panel.new()
	victory_panel.position = Vector2(276, 200)  # Centered position
	victory_panel.size = Vector2(600, 300)
	victory_panel.modulate = color * 0.3 + Color.WHITE * 0.7  # Tinted background
	victory_overlay.add_child(victory_panel)
	
	# Victory title - large and centered
	var title_label = Label.new()
	title_label.text = title
	title_label.position = Vector2(50, 50)
	title_label.size = Vector2(500, 80)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", kongtext_font)
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", color)
	victory_panel.add_child(title_label)
	
	# Reason text - smaller, centered
	var reason_label = Label.new()
	reason_label.text = reason
	reason_label.position = Vector2(50, 140)
	reason_label.size = Vector2(500, 60)
	reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reason_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reason_label.add_theme_font_override("font", kongtext_font)
	reason_label.add_theme_font_size_override("font_size", 24)
	reason_label.add_theme_color_override("font_color", Color.WHITE)
	reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	victory_panel.add_child(reason_label)
	
	# Continue button - centered at bottom
	var continue_button = Button.new()
	continue_button.text = "Continue to Game Over"
	continue_button.position = Vector2(200, 220)
	continue_button.size = Vector2(200, 50)
	continue_button.add_theme_font_override("font", kongtext_font)
	continue_button.add_theme_font_size_override("font_size", 18)
	continue_button.pressed.connect(_on_victory_continue_pressed)
	victory_panel.add_child(continue_button)
	
	# Optional: Add pulsing animation to title
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "modulate", color * 1.2, 1.0)
	tween.tween_property(title_label, "modulate", color * 0.8, 1.0)

func _on_victory_continue_pressed():
	"""Handle victory screen continue button - transition to game over"""
	if has_node("/root/Music"):
		var music = get_node("/root/Music")
		if music.has_method("mouse_click"):
			music.mouse_click()
	
	# Clean up victory overlay
	if victory_overlay:
		victory_overlay.queue_free()
		victory_overlay = null
	
	# Transition to game over screen
	get_tree().change_scene_to_file("res://game_scenes/game_over_screen/game_over.tscn")

# Enhanced dice system event handlers
func show_enhanced_dice_popup():
	"""Show enhanced dice popup for connected attack chain system"""
	if active_dice_popup:
		return
	
	print("=== SHOWING ENHANCED DICE POPUP ===")
	print("Round: ", round_number)
	if GameData:
		GameData.debug_show_game_state()
	
	active_dice_popup = dice_popup_scene.instantiate()
	add_child(active_dice_popup)
	
	# Ensure proper size and positioning
	active_dice_popup.position = Vector2.ZERO
	active_dice_popup.size = Vector2(1152, 648)
	active_dice_popup.z_index = 100
	
	# Connect signals
	if active_dice_popup.has_signal("dice_completed"):
		active_dice_popup.dice_completed.connect(_on_enhanced_dice_completed)
	if active_dice_popup.has_signal("dice_cancelled"):
		active_dice_popup.dice_cancelled.connect(_on_dice_popup_cancelled)

func _on_enhanced_dice_completed(results: Array):
	print("=== ENHANCED DICE COMPLETED ===")
	print("Individual results received: ", results.size())

	current_roll_results = results.duplicate()

	if GameData:
		GameData.record_dice_results(results)

	close_dice_popup()

	if results.size() > 0:
		process_connected_attack_results()
	else:
		print("⚠️ No results — skipping to next round anyway")
		round_number += 1
		if GameData:
			GameData.prepare_next_round()
		continue_connected_game_flow()


func _on_discussion_time_completed(results: Array):
	"""Handle discussion time completion from GameData"""
	print("=== DISCUSSION TIME COMPLETED ===")
	# The dice popup handles the discussion, so we continue game flow here
	continue_connected_game_flow()

func process_connected_attack_results():
	"""Process the results of connected attack chains"""
	if current_roll_results.size() == 0:
		return
	
	print("=== PROCESSING CONNECTED ATTACK RESULTS ===")
	
	# Show individual result summary
	for result in current_roll_results:
		var status = "SUCCESS" if result.success else "FAILURE"
		if result.has("invalid_play") and result.invalid_play:
			status = "INVALID PLAY"
		elif result.auto_success:
			status = "AUTO SUCCESS"
		elif result.has("skipped") and result.skipped:
			status = "SKIPPED"
		elif result.has("moderator_override"):
			status = "MODERATOR OVERRIDE: " + result.moderator_override
		
		print("Attack ", result.attack_index + 1, ": ", result.attack_name, " - ", status)
		if result.has("individual_cost"):
			print("  Individual calculation: Cost ", result.individual_cost, "/Time ", result.individual_time, " = ", result.success_percentage, "%")
	
	# Build and save comprehensive CSV data
	var row = build_connected_csv_row()
	save_connected_game_data(row)
	print("CSV row built and saved for round ", round_number)
	
	# Progress to next round
	round_number += 1
	if GameData:
		GameData.prepare_next_round()
	
	# Reset for next round
	current_roll_results.clear()

func build_connected_csv_row() -> Array:
	"""Build CSV row for connected attack chain system"""
	print("=== BUILDING CSV ROW ===")
	
	var timestamp = Time.get_time_string_from_system()
	var row = [str(round_number - 1), timestamp]  # -1 because we increment after
	
	print("Round: ", round_number - 1, " | Timestamp: ", timestamp)
	
	# Get position states from GameData
	var starting_positions = []
	var ending_positions = []
	
	if GameData:
		var history = GameData.game_history
		print("GameData history size: ", history.size())
		if history.size() > 0:
			var latest_round = history[history.size() - 1]
			starting_positions = latest_round.get("starting_positions", [])
			ending_positions = latest_round.get("ending_positions", [])
			print("Starting positions: ", starting_positions)
			print("Ending positions: ", ending_positions)
	
	# Add starting positions
	for i in range(3):
		if i < starting_positions.size():
			row.append(starting_positions[i].state)
		else:
			row.append("EMPTY")
	
	print("Current roll results: ", current_roll_results.size())
	
	# Add individual attack card data
	for i in range(3):
		var found_result = false
		for result in current_roll_results:
			if result.attack_index == i:
				row.append(result.attack_name)
				row.append(result.individual_cost if result.has("individual_cost") else "N/A")
				row.append(result.individual_time if result.has("individual_time") else "N/A")
				# Determine attack type from GameData
				var attack_type = "IA"  # Default
				if GameData and GameData.current_attack_cards.size() > i:
					attack_type = GameData.current_attack_cards[i].get("card_type", "IA")
				row.append(attack_type)
				found_result = true
				print("Added attack ", i + 1, ": ", result.attack_name)
				break
		
		if not found_result:
			row.append_array(["---", "---", "---", "---"])
			print("No attack found for position ", i + 1)
	
	# Add defense data
	print("Defense cards: ", dCards.size())
	for i in range(3):
		if i < dCards.size() and dCards[i] and dCards[i].card_index != -1:
			var card = dCards[i]
			var defense_name = get_defense_name_safe(card)
			var maturity = card.getMaturityValue() if card.has_method("getMaturityValue") else 1
			# Check if eviction card
			var is_eviction = false
			if GameData:
				is_eviction = GameData.is_eviction_card(card)
			row.append(defense_name)
			row.append(maturity)
			row.append("Yes" if is_eviction else "No")
			print("Added defense ", i + 1, ": ", defense_name, " (Maturity: ", maturity, ")")
		else:
			row.append_array(["---", "---", "---"])
			print("No defense found for position ", i + 1)
	
	# Add individual results
	for i in range(3):
		var found_result = false
		for result in current_roll_results:
			if result.attack_index == i:
				if result.has("skipped") and result.skipped:
					row.append("Skipped")
				elif result.has("moderator_override"):
					row.append("Moderator: " + result.moderator_override)
				else:
					row.append("Success" if result.success else "Failure")
				row.append("AUTO" if result.auto_success else str(result.roll_result))
				row.append("Yes" if result.success else "No")
				# Determine new state
				var new_state = "Unknown"
				if ending_positions.size() > i:
					new_state = ending_positions[i].state
				row.append(new_state)
				found_result = true
				print("Added result ", i + 1, ": ", ("Success" if result.success else "Failure"))
				break
		
		if not found_result:
			row.append_array(["---", "---", "---", "---"])
			print("No result found for position ", i + 1)
	
	# Add ending positions
	for i in range(3):
		if i < ending_positions.size():
			row.append(ending_positions[i].state)
		else:
			row.append("EMPTY")
	
	# Check for red team victory
	var red_victory = false
	for pos in ending_positions:
		if pos.state == "E/E":
			red_victory = true
			break
	row.append("Yes" if red_victory else "No")
	
	# Add round notes
	var notes = "Round " + str(round_number - 1) + " completed. "
	var successes = 0
	for result in current_roll_results:
		if result.success and not (result.has("skipped") and result.skipped):
			successes += 1
	notes += str(successes) + "/" + str(current_roll_results.size()) + " attacks succeeded."
	row.append(notes)
	
	print("Final row size: ", row.size())
	print("=== CSV ROW COMPLETE ===")
	
	return row

func save_connected_game_data(row: Array):
	"""Save connected game data to CSV file"""
	print("=== SAVING CSV DATA ===")
	print("Row data: ", row)
	print("Save path: ", save_path)
	
	var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_csv_line(row)
		file.close()
		print("✅ Connected game data saved for round ", round_number - 1)
		
		# Verify the file was written
		var verify_file = FileAccess.open(save_path, FileAccess.READ)
		if verify_file:
			var content = verify_file.get_as_text()
			print("📄 Current CSV file size: ", content.length(), " characters")
			print("📄 Lines in file: ", content.split("\n").size())
			verify_file.close()
		else:
			print("❌ Could not verify CSV file")
	else:
		print("❌ ERROR: Could not open CSV file for writing: ", save_path)
		print("❌ Error code: ", FileAccess.get_open_error())

func get_defense_name_safe(defense_card) -> String:
	"""Get defense card name safely"""
	if not defense_card:
		return "No Defense"

	var card_index = defense_card.card_index
	if card_index == 0:
		print("Skipping card_index 0 (likely header row)")
		return "Unknown Defense"

	if has_node("/root/Mitre"):
		var mitre = get_node("/root/Mitre")
		if mitre.defend_dict.has(card_index):
			return mitre.defend_dict[card_index][3]  # Defense: index 3 = Name
	return "Defense Card"

func continue_connected_game_flow():
	"""Continue game flow after connected attack resolution"""
	reset_cards_for_next_round()
	show_round_info_popup(round_number)

func continue_connected_game_flow_resume():
	"""Resume gameplay after round popup is dismissed"""
	var timer1 = get_node_or_null("Timer_Label")
	var pause_button = get_node_or_null("Timer_Label/pause")
	var timeline = get_node_or_null("timeline")
	var attack_dropdown = get_node_or_null("dropdown/attack_option")
	var defend_dropdown = get_node_or_null("dropdown/defend_option")
	var dropdown = get_node_or_null("dropdown")


	disable_attack_buttons(false)
	for card in aCards:
		if card and card.has_method("disable_buttons"):
			card.disable_buttons(true)

	if pause_button:
		pause_button.disabled = false
	if timer1:
		timer1.play = true

	var total_time = calculate_total_time_used()
	if timeline and timeline.has_method("_progress"):
		timeline._progress(total_time * 25)
	if timeline and timeline.has_method("increase_time"):
		timeline.increase_time()

	if dropdown and dropdown.has_method("set_card_references"):
		dropdown.set_card_references(aCards, dCards)


	print("=== ROUND ", round_number, " READY ===")
	if GameData:
		GameData.debug_show_game_state()

func show_round_info_popup(round_index: int):
	var mitre = get_node("/root/Mitre")
	if not mitre or not mitre.timeline_dict.has(round_index):
		print("⚠️ No timeline data for round ", round_index)
		continue_connected_game_flow_resume()
		return

	var timeline_data = mitre.timeline_dict[round_index]
	var time = timeline_data[0]
	var header = timeline_data[1]
	var description = timeline_data[2]
	var subsystems = timeline_data[3]

	var popup = round_info_popup_scene.instantiate()
	add_child(popup)
	popup.set_round_info(round_index, header, description, subsystems)
	popup.round_info_closed.connect(continue_connected_game_flow_resume)


func calculate_total_time_used() -> int:
	"""Calculate total time used by all successful attacks"""
	var total_time = 0
	for result in current_roll_results:
		if result.success and result.has("individual_time") and not (result.has("skipped") and result.skipped):
			total_time += result.individual_time
	return total_time

func reset_cards_for_next_round():
	"""Reset all cards for the next round"""
	for card in aCards:
		if card:
			if card.expanded:
				if card.has_method("make_small_again"):
					card.make_small_again()
			if card.has_method("reset_card"):
				card.reset_card()
	
	for card in dCards:
		if card:
			if card.expanded:
				if card.has_method("make_small_again"):
					card.make_small_again()
			if card.has_method("reset_card"):
				card.reset_card()

# Game flow control functions
func disable_attack_buttons(state: bool):
	"""Disable/enable attack buttons and cards"""
	for button in attackbuttons:
		if button:
			button.disabled = state
	for card in aCards:
		if card and card.inPlay:
			if card.has_method("disable_buttons"):
				card.disable_buttons(state)

func disable_defend_buttons(state: bool):
	"""Disable/enable defense buttons and cards"""
	for button in defendbuttons:
		if button:
			button.disabled = state
	for card in dCards:
		if card and card.has_method("disable_buttons"):
			card.disable_buttons(state)

func collapse_all_cards():
	"""Collapse all expanded cards"""
	for card in aCards + dCards:
		if card and card.expanded:
			if card.has_method("make_small_again"):
				card.make_small_again()

func has_active_attacks() -> bool:
	"""Check if there are active attack cards"""
	for card in aCards:
		if card and card.card_index != -1:
			return true
	return false

func has_active_defenses() -> bool:
	"""Check if there are active defense cards"""
	for card in dCards:
		if card and card.card_index != -1:
			return true
	return false

# Signal handlers for connected attack chain system
func _on_attack_chain_victory():
	"""Handle Red Team victory through connected attack chains"""
	handle_red_team_victory("Connected attack chain reached E/E!")

func _on_timeline_victory():
	"""Handle Blue Team victory through timeline completion"""
	handle_blue_team_victory("Timeline completed")

func _on_dice_roll_completed():
	"""Legacy compatibility for GameData signal"""
	print("Legacy dice roll completed signal received")

func _on_dice_popup_cancelled():
	"""Handle dice popup cancellation"""
	close_dice_popup()
	# Return to defense phase
	disable_defend_buttons(false)
	var pause_button = get_node_or_null("Timer_Label/pause")
	if pause_button:
		pause_button.disabled = false

func close_dice_popup():
	"""Close the active dice popup"""
	if active_dice_popup:
		active_dice_popup.queue_free()
		active_dice_popup = null

# Standard game event handlers
func _on_pause_pressed():
	"""Handle pause button press"""
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	
	if currenttimer == 0 and timer1:
		timer1.play = !timer1.play
		disable_attack_buttons(!timer1.play)
		if timer1.play:
			disable_defend_buttons(true)
	elif currenttimer == 1 and timer2:
		timer2.play = !timer2.play
		disable_attack_buttons(!timer2.play)
		if timer2.play:
			disable_defend_buttons(false)

func _on_start_game_pressed():
	var timer1 = get_node_or_null("Timer_Label")
	var pause_button = get_node_or_null("Timer_Label/pause")
	var start_game = get_node_or_null("CanvasLayer/StartGame")
	var color_rect = get_node_or_null("CanvasLayer/ColorRect")
	var end_game = get_node_or_null("EndGame")

	if timer1:
		timer1.play = true
	disable_attack_buttons(false)
	for card in aCards:
		if card and card.has_method("disable_buttons"):
			card.disable_buttons(true)
	if pause_button:
		pause_button.disabled = false
	if start_game:
		start_game.visible = false
	if color_rect:
		color_rect.visible = false
	if end_game:
		end_game.visible = true

	print("=== CONNECTED ATTACK CHAIN GAME STARTED ===")
	print("Round: ", round_number)

	# 👇 Add this line:
	show_round_info_popup(round_number - 1)


func _on_attack_submit_pressed():
	"""Handle attack submit button press"""
	if not has_active_attacks():
		return
	
	collapse_all_cards()
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	var defense_submit = get_node_or_null("DefenseSubmit")
	
	if timer1:
		timer1.play = false
	if timer2:
		timer2.play = true
	disable_attack_buttons(true)
	disable_defend_buttons(false)
	for card in dCards:
		if card and card.has_method("disable_buttons"):
			card.disable_buttons(true)
	if defense_submit:
		defense_submit.disabled = false

func _on_defense_submit_pressed():
	"""Handle defense submit button press - start connected attack resolution"""
	collapse_all_cards()
	var timer2 = get_node_or_null("Timer_Label2")
	var pause_button = get_node_or_null("Timer_Label/pause")
	
	if timer2:
		timer2.play = false
	disable_defend_buttons(true)
	if pause_button:
		pause_button.disabled = true
	
	# Capture current card state for connected attack system
	if use_dice_system and GameData:
		print("=== STARTING CONNECTED ATTACK RESOLUTION ===")
		print("Round: ", round_number)
		GameData.capture_current_cards(aCards, dCards)
		
		# Debug output to verify connected calculations
		if GameData.has_method("debug_show_attack_table"):
			GameData.debug_show_attack_table()
		if GameData.has_method("debug_show_game_state"):
			GameData.debug_show_game_state()
		
		# Add a small delay to ensure UI updates
		await get_tree().create_timer(0.1).timeout
		show_enhanced_dice_popup()
	else:
		show_manual_input()

func show_manual_input():
	"""Show manual input window (legacy fallback)"""
	var window = get_node_or_null("Window")
	if window:
		window.visible = true

# Other standard event handlers (end game, quit, etc.) remain the same
func _on_end_game_pressed():
	"""Handle end game button press"""
	_on_pause_pressed()
	var end_game = get_node_or_null("EndGame")
	var pause_button = get_node_or_null("Timer_Label/pause")
	var window2 = get_node_or_null("Window2")
	if end_game:
		end_game.disabled = true
	if pause_button:
		pause_button.disabled = true
	if window2:
		window2.visible = true

func _on_quit_button_pressed():
	"""Handle quit button press"""
	print("=== GAME ENDING ===")
	
	# Save any remaining data before quitting
	if current_roll_results.size() > 0:
		print("Saving remaining roll results before quit...")
		var row = build_connected_csv_row()
		save_connected_game_data(row)
	
	# Export final data
	export_final_game_data("MANUAL_QUIT")
	
	if has_node("/root/Music"):
		var music = get_node("/root/Music")
		if music.has_method("mouse_click"):
			music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/game_over_screen/game_over.tscn")

func _on_continue_button_pressed():
	"""Handle continue button press"""
	_on_pause_pressed()
	var end_game = get_node_or_null("EndGame")
	var pause_button = get_node_or_null("Timer_Label/pause")
	var window2 = get_node_or_null("Window2")
	if end_game:
		end_game.disabled = false
	if pause_button:
		pause_button.disabled = false
	if window2:
		window2.visible = false

func _on_help_pressed():
	"""Handle help button press - also export current data for debugging"""
	# Export current game state for debugging
	debug_export_current_state()
	
	var window5 = get_node_or_null("Window5")
	if window5:
		window5.visible = true

func debug_export_current_state():
	"""Debug function to export current game state"""
	print("=== DEBUG: EXPORTING CURRENT STATE ===")
	
	# Show current round data
	print("Current round: ", round_number)
	print("Current roll results: ", current_roll_results.size())
	for i in range(current_roll_results.size()):
		var result = current_roll_results[i]
		print("  Result ", i, ": Attack ", result.attack_index + 1, " - ", result.attack_name, " - ", ("Success" if result.success else "Failure"))
	
	# Show GameData history
	if GameData:
		print("GameData history size: ", GameData.game_history.size())
		for i in range(GameData.game_history.size()):
			var round_data = GameData.game_history[i]
			print("  Round ", round_data.round_number, ": ", round_data.results.size(), " results")
	
	# Create debug export
	var debug_data = {
		"current_round": round_number,
		"roll_results": current_roll_results,
		"gamedata_history": GameData.game_history if GameData else [],
		"export_time": Time.get_time_string_from_system()
	}
	
	var debug_path = OS.get_user_data_dir() + "/seacat_debug_export.json"
	var debug_file = FileAccess.open(debug_path, FileAccess.WRITE)
	if debug_file:
		debug_file.store_string(JSON.stringify(debug_data, "  "))
		debug_file.close()
		print("✅ Debug export saved to: ", debug_path)
	else:
		print("❌ Could not save debug export")
	
	# Also try to save current CSV data if we have results
	if current_roll_results.size() > 0:
		print("Forcing CSV save of current results...")
		var row = build_connected_csv_row()
		save_connected_game_data(row)
	
	print("=== DEBUG EXPORT COMPLETE ===")

func _on_window_close_requested():
	"""Handle help window close"""
	var window5 = get_node_or_null("Window5")
	if window5:
		window5.visible = false

# Legacy event handlers for manual input compatibility
func _on_option_button_item_selected(index):
	"""Handle manual option selection (legacy compatibility)"""
	pass

func _on_spin_box_value_changed(value):
	"""Handle manual spin box value change (legacy compatibility)"""
	pass

func _on_button_pressed():
	"""Handle manual button press (legacy compatibility)"""
	pass
