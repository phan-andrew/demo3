extends Node2D

# Core game references
var aCards = []
var dCards = []
var attackbuttons = []
var defendbuttons = []
var timers = []

# Game state variables
var save_path = OS.get_user_data_dir() + "/game_data.txt"
var currenttimer = 0
var timeTaken = 0
var game_won = false

# Attack chain system variables
var current_roll_results = []
var attack_progress_bars = []

# UI icons
var playIcon = preload("res://images/UI_images/play_button.png")
var pauseIcon = preload("res://images/UI_images/pause_button.png")

# Dice system
var use_dice_system = true
var dice_popup_scene = preload("res://game_scenes/dice_screen/dice_popup.tscn")
var active_dice_popup = null

func _ready():
	initialize_game()
	setup_connections()

func initialize_game():
	"""Initialize the game with attack chain system"""
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
	
	# Setup save file with attack chain headers
	setup_enhanced_save_file()
	
	# Setup attack chain progress UI
	setup_attack_chain_progress_ui()
	
	# Initialize GameData attack chains
	if GameData:
		GameData.reset_attack_chains()
	
	# Start background music
	if has_node("/root/Music"):
		var music = get_node("/root/Music")
		if music.has_method("play_music"):
			music.play_music()

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
	"""Setup signal connections for attack chain system"""
	if GameData:
		# Connect attack chain signals
		if not GameData.dice_roll_completed_signal.is_connected(_on_dice_roll_completed):
			GameData.dice_roll_completed_signal.connect(_on_dice_roll_completed)
		if not GameData.defense_reallocation_needed.is_connected(_on_defense_reallocation_needed):
			GameData.defense_reallocation_needed.connect(_on_defense_reallocation_needed)
		if not GameData.attack_chain_victory.is_connected(_on_attack_chain_victory):
			GameData.attack_chain_victory.connect(_on_attack_chain_victory)
		if not GameData.timeline_victory.is_connected(_on_timeline_victory):
			GameData.timeline_victory.connect(_on_timeline_victory)

func setup_enhanced_save_file():
	"""Setup CSV with enhanced headers for attack chain tracking"""
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var headers = ["Time", "Attack 1", "Attack 2", "Attack 3", "Defense 1", "Defense 2", "Defense 3"]
		headers.append_array(["A1 Roll", "A1 Success", "A2 Roll", "A2 Success", "A3 Roll", "A3 Success"])
		headers.append_array(["Overall Success", "Risk Analysis"])
		headers.append_array(["A1 Chain Step", "A2 Chain Step", "A3 Chain Step"])
		file.store_csv_line(headers)
		file.close()

func setup_attack_chain_progress_ui():
	"""Setup UI elements for attack chain progress tracking"""
	attack_progress_bars = []
	
	# Create or find progress display container
	var progress_display = get_node_or_null("AttackProgressDisplay")
	if not progress_display:
		progress_display = VBoxContainer.new()
		progress_display.name = "AttackProgressDisplay"
		progress_display.position = Vector2(50, 200)
		add_child(progress_display)
		
		# Add title label
		var title_label = Label.new()
		title_label.text = "Attack Chain Progress:"
		title_label.add_theme_font_size_override("font_size", 16)
		progress_display.add_child(title_label)
	
	# Create progress bars for each attack line
	for i in range(3):
		var progress_container = create_attack_progress_display(i)
		progress_display.add_child(progress_container)
		attack_progress_bars.append(progress_container)
func create_attack_progress_display(attack_index: int) -> Control:
	"""Create progress display for a single attack line"""
	var container = HBoxContainer.new()
	container.name = "AttackProgress" + str(attack_index)
	container.add_theme_constant_override("separation", 5)
	
	# Attack label
	var label = Label.new()
	label.text = "Attack " + str(attack_index + 1) + ":"
	label.custom_minimum_size = Vector2(80, 25)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	# Progress steps with better visual styling
	var steps = ["IA", "PEP", "E/E"]
	for i in range(steps.size()):
		var step_panel = Panel.new()
		step_panel.custom_minimum_size = Vector2(45, 25)
		step_panel.name = "Step" + str(i)
		
		var step_label = Label.new()
		step_label.text = steps[i]
		step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		step_label.name = "StepLabel"
		
		step_panel.add_child(step_label)
		container.add_child(step_panel)
		
		# Add arrow between steps (except after last step)
		if i < steps.size() - 1:
			var arrow_label = Label.new()
			arrow_label.text = "→"
			arrow_label.custom_minimum_size = Vector2(20, 25)
			arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			container.add_child(arrow_label)
	
	return container

func _process(_delta):
	"""Main game loop"""
	handle_card_expansion_state()
	update_timer_display()
	update_theme_background()
	update_attack_progress_display()
	check_game_end_conditions()
	
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

func update_attack_progress_display():
	"""Update attack chain progress displays"""
	if not GameData:
		return
	
	var progress_info = GameData.get_attack_chain_progress()
	
	for i in range(min(progress_info.size(), attack_progress_bars.size())):
		var info = progress_info[i]
		var display = attack_progress_bars[i]
		
		if not display:
			continue
		
		# Update step highlighting
		for j in range(3):  # IA, PEP, E/E
			var step_panel = display.get_node_or_null("Step" + str(j))
			if step_panel:
				var step_label = step_panel.get_node_or_null("StepLabel")
				if step_label:
					if info.active:
						# Highlight current and completed steps
						if j < int(info.step_number) - 1:
							# Completed steps - green
							step_label.modulate = Color.GREEN
							step_panel.modulate = Color(0.2, 0.8, 0.2, 0.3)  # Light green background
						elif j == int(info.step_number) - 1:
							# Current step - yellow
							step_label.modulate = Color.YELLOW
							step_panel.modulate = Color(0.8, 0.8, 0.2, 0.3)  # Light yellow background
						else:
							# Future steps - gray
							step_label.modulate = Color.GRAY
							step_panel.modulate = Color(0.5, 0.5, 0.5, 0.1)  # Light gray background
					else:
						# Inactive attack line
						step_label.modulate = Color.DARK_GRAY
						step_panel.modulate = Color(0.3, 0.3, 0.3, 0.1)  # Very light gray background

func check_game_end_conditions():
	"""Check for game end conditions"""
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
	
	# Check attack chain victory (Red team victory) - handled by GameData signal
	
	if timer1_expired or timer2_expired or timeline_completed:
		handle_blue_team_victory("Time/Timeline completed")

func handle_red_team_victory(reason: String):
	"""Handle Red Team (attack chain) victory"""
	print("🔴 RED TEAM WINS: ", reason)
	game_won = true
	show_victory_screen("🔴 RED TEAM VICTORY!", reason, Color.RED)

func handle_blue_team_victory(reason: String):
	"""Handle Blue Team (defense) victory"""
	print("🔵 BLUE TEAM WINS: ", reason)
	game_won = true
	show_victory_screen("🔵 BLUE TEAM VICTORY!", reason, Color.BLUE)

func show_victory_screen(title: String, reason: String, color: Color):
	"""Show victory screen with team colors"""
	var victory_label = get_node_or_null("VictoryLabel")
	if not victory_label:
		victory_label = Label.new()
		victory_label.name = "VictoryLabel"
		victory_label.position = Vector2(400, 300)
		victory_label.add_theme_font_size_override("font_size", 32)
		victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(victory_label)
	
	victory_label.text = title + "\n" + reason
	victory_label.modulate = color
	victory_label.visible = true
	
	# Auto-transition to game over after delay
	await get_tree().create_timer(3.0).timeout
	_on_quit_button_pressed()

# Game flow control
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

# Enhanced dice system event handlers
func show_enhanced_dice_popup():
	"""Show enhanced dice popup for attack chain system"""
	if active_dice_popup:
		return
	
	print("Showing enhanced dice popup")
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
	if active_dice_popup.has_signal("defense_reallocation_complete"):
		active_dice_popup.defense_reallocation_complete.connect(_on_defense_reallocation_complete)

func _on_enhanced_dice_completed(results: Array):
	"""Handle completion of enhanced dice rolling"""
	print("Enhanced dice rolling completed with ", results.size(), " results")
	
	current_roll_results = results.duplicate()
	
	# Record results in GameData
	if GameData:
		GameData.record_dice_results(results)
	
	close_dice_popup()
	process_battle_results()

func _on_defense_reallocation_needed():
	"""Handle defense reallocation request from GameData"""
	print("Defense reallocation needed - showing UI")
	# The dice popup will handle the reallocation UI
	
func _on_defense_reallocation_complete():
	"""Handle defense reallocation completion"""
	print("Defense reallocation completed")
	# Refresh the dice popup with new pairings
	if active_dice_popup:
		close_dice_popup()
		await get_tree().create_timer(0.5).timeout
		show_enhanced_dice_popup()

func _on_attack_chain_victory():
	"""Handle Red Team victory through attack chains"""
	handle_red_team_victory("All attacks reached E/E")

func _on_timeline_victory():
	"""Handle Blue Team victory through timeline completion"""
	handle_blue_team_victory("Timeline completed")

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

func process_battle_results():
	"""Process the results of the battle and continue game flow"""
	if current_roll_results.size() == 0:
		return
	
	# Build and save CSV data
	var row = build_enhanced_csv_row()
	save_game_data(row)
	
	# Continue normal game flow
	continue_normal_game_flow()
	
	# Reset for next round
	current_roll_results.clear()

func build_enhanced_csv_row() -> Array:
	"""Build enhanced CSV row with attack chain progression"""
	timeTaken = 0
	for card in aCards:
		if card and card.inPlay:
			if card.has_method("getTimeValue"):
				timeTaken += card.getTimeValue()
	
	var row = [Time.get_time_string_from_system()]
	
	# Add attack cards
	for card in aCards:
		if card and card.card_index != -1:
			if card.has_method("getString"):
				row.append(card.getString())
			else:
				row.append("Attack Card")
			# Reset card
			if card.expanded:
				if card.has_method("make_small_again"):
					card.make_small_again()
			if card.has_method("reset_card"):
				card.reset_card()
		else:
			row.append("---")
	
	# Add defense cards
	for card in dCards:
		if card and card.card_index != -1:
			if card.has_method("getString"):
				row.append(card.getString())
			else:
				row.append("Defense Card")
			if card.expanded:
				if card.has_method("make_small_again"):
					card.make_small_again()
			if card.has_method("reset_card"):
				card.reset_card()
		else:
			row.append("---")
	
	# Add individual roll results
	for i in range(3):
		var found_result = false
		for result in current_roll_results:
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
	for result in current_roll_results:
		if result.success:
			overall_success = true
			break
	
	row.append("Success" if overall_success else "Failure")
	row.append("---")  # Risk analysis placeholder
	
	# Add attack chain steps
	if GameData:
		var progress_info = GameData.get_attack_chain_progress()
		for i in range(3):
			if i < progress_info.size():
				row.append(progress_info[i].current_step)
			else:
				row.append("---")
	else:
		row.append_array(["---", "---", "---"])
	
	return row

func save_game_data(row: Array):
	"""Save game data to CSV file"""
	var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_csv_line(row)
		file.close()

func continue_normal_game_flow():
	"""Continue normal game flow after battle resolution"""
	var timer1 = get_node_or_null("Timer_Label")
	var pause_button = get_node_or_null("Timer_Label/pause")
	var timeline = get_node_or_null("timeline")
	var attack_dropdown = get_node_or_null("dropdown/attack_option")
	var defend_dropdown = get_node_or_null("dropdown/defend_option")
	
	# Resume attack phase
	disable_attack_buttons(false)
	for card in aCards:
		if card and card.has_method("disable_buttons"):
			card.disable_buttons(true)
	
	if pause_button:
		pause_button.disabled = false
	if timer1:
		timer1.play = true
	
	# Progress timeline
	if timeline and timeline.has_method("_progress"):
		timeline._progress(timeTaken * 25)
	if timeline and timeline.has_method("increase_time"):
		timeline.increase_time()
	
	# Reset dropdowns
	if attack_dropdown and attack_dropdown.has_method("select"):
		attack_dropdown.select(-1)
	if defend_dropdown and defend_dropdown.has_method("select"):
		defend_dropdown.select(-1)
	
	timeTaken = 0

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
	"""Handle start game button press"""
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
	"""Handle defense submit button press"""
	collapse_all_cards()
	var timer2 = get_node_or_null("Timer_Label2")
	var pause_button = get_node_or_null("Timer_Label/pause")
	
	if timer2:
		timer2.play = false
	disable_defend_buttons(true)
	if pause_button:
		pause_button.disabled = true
	
	# Capture current card state and show dice system
	if use_dice_system and GameData:
		print("Capturing cards for dice system...")
		GameData.capture_current_cards(aCards, dCards)
		
		# Debug output to verify table usage
		print("=== VERIFYING ATTACK TABLE USAGE ===")
		if GameData.has_method("debug_show_attack_table"):
			GameData.debug_show_attack_table()
		
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

func _on_dice_roll_completed():
	"""Legacy compatibility for GameData signal"""
	print("Legacy dice roll completed signal received")

# Other standard event handlers (end game, quit, etc.)
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
	"""Handle help button press"""
	var window5 = get_node_or_null("Window5")
	if window5:
		window5.visible = true

func _on_window_close_requested():
	"""Handle help window close"""
	var window5 = get_node_or_null("Window5")
	if window5:
		window5.visible = false

# Legacy event handlers for manual input compatibility
func _on_option_button_item_selected(index):
	"""Handle manual option selection"""
	# Legacy compatibility - not used in attack chain system
	pass

func _on_spin_box_value_changed(value):
	"""Handle manual spin box value change"""
	# Legacy compatibility - not used in attack chain system
	pass

func _on_button_pressed():
	"""Handle manual button press"""
	# Legacy compatibility - not used in attack chain system
	pass

func print_card_debug_info():
	"""Print debug information about current card state"""
	print("=== CARD DEBUG INFO ===")
	print("Attack Cards:")
	for i in range(aCards.size()):
		var card = aCards[i]
		if card:
			print("  a_", i + 1, ": inPlay=", card.inPlay, " card_index=", card.card_index, " cardType=", card.cardType)
		else:
			print("  a_", i + 1, ": NULL")
	
	print("Defense Cards:")
	for i in range(dCards.size()):
		var card = dCards[i]
		if card:
			print("  d_", i + 1, ": inPlay=", card.inPlay, " card_index=", card.card_index, " cardType=", card.cardType)
		else:
			print("  d_", i + 1, ": NULL")
	
	if GameData:
		print("GameData attack lines:")
		for i in range(3):
			var line = GameData.attack_lines[i]
			print("  Attack ", i + 1, ": active=", line.active, " step=", GameData.get_step_name(line.step), " card_index=", line.card_index)
	
	print("=== END DEBUG INFO ===")
