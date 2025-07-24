extends Node2D

# Core game references - will be populated safely in _ready()
var aCards = []
var dCards = []
var attackbuttons = []
var defendbuttons = []
var timers = []

# Game state variables
var save_path = OS.get_user_data_dir() + "/game_data.txt"
var successornah = ""
var sucornah = false
var likelihood = 0
var riskanalysis = 0
var currenttimer = 0
var finalattack = false
var timeTaken = 0
var variables = [0, 0, 0]

# UI icons
var playIcon = preload("res://images/UI_images/play_button.png")
var pauseIcon = preload("res://images/UI_images/pause_button.png")

# Dice system - using existing dice popup
var use_dice_system = true
var dice_popup_scene = preload("res://game_scenes/dice_screen/dice_popup.tscn")
var active_dice_popup = null

func _ready():
	initialize_game()
	setup_connections()

func initialize_game():
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
	
	# Update button arrays to match actual cards found
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
	
	# Connect dropdown to card arrays for generation
	var dropdown = get_node_or_null("dropdown")
	if dropdown and dropdown.has_method("set_card_references"):
		dropdown.set_card_references(aCards, dCards)
	
	# Initialize timer arrays
	timers = []
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	if timer1:
		timers.append(timer1)
		var pause_button = timer1.get_node_or_null("pause")
		if pause_button:
			pause_button.disabled = true
	if timer2:
		timers.append(timer2)
	
	# Initial button states
	disable_attack_buttons(true)
	disable_defend_buttons(true)
	
	# Initial UI state
	var window = get_node_or_null("Window")
	if window:
		window.visible = false
	var end_game = get_node_or_null("EndGame")
	if end_game:
		end_game.visible = false
	currenttimer = 0
	
	# Initialize timer displays
	for timer in timers:
		if timer and timer.get("initialTime") !=null:
			var initialTime = timer.initialTime
			var minutes = int(initialTime) / 60
			var seconds = int(initialTime) % 60
			timer.text = str(minutes) + (":%02d" % seconds)
	
	# Initialize save file
	setup_save_file()
	
	# Start music (let Music.gd handle details)
	if has_node("/root/Music"):
		var music = get_node("/root/Music")
		if music.has_method("play_music"):
			music.play_music()

func setup_connections():
	# Connect to GameData for dice system
	if GameData:
		GameData.dice_roll_completed_signal.connect(_on_dice_roll_completed)

func setup_save_file():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_csv_line(["Time","Attack 1","Attack 2", "Attack 3","Defense 1", "Defense 2", "Defense 3", "Attack Success","Attack Success Likelihood","Risk Analysis","D1 APL", "D2 APL", "D3 APL"])
		file.close()

func _process(_delta):
	handle_card_expansion_state()
	update_timer_display()
	update_theme_background()
	check_game_end_conditions()
	handle_debug_input()
	
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

func handle_card_expansion_state():
	# Simplified expansion logic
	var attack_expanded = false
	var defense_expanded = false
	
	for card in aCards:
		if card.expanded:
			attack_expanded = true
			break
	
	for card in dCards:
		if card.expanded:
			defense_expanded = true
			break
	
	# Only disable other cards when one is expanded
	if attack_expanded:
		for card in aCards:
			if not card.expanded:
				card.disable_expand(true)
	else:
		for card in aCards:
			if card.inPlay:
				card.disable_expand(false)
				card.disable_flip(false)
	
	if defense_expanded:
		for card in dCards:
			if not card.expanded:
				card.disable_expand(true)
	else:
		for card in dCards:
			if card.inPlay:
				card.disable_expand(false)
				card.disable_flip(false)

func update_timer_display():
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	
	if timer1 and timer1.get("play") == true:
		currenttimer = 0
	elif timer2 and timer2.get("play") == true:
		currenttimer = 1
	
	# Update pause button icon
	var pause_button = get_node_or_null("Timer_Label/pause")
	if pause_button:
		var timer1_playing = timer1 and timer1.get("play") == true
		var timer2_playing = timer2 and timer2.get("play") == true
		pause_button.icon = playIcon if not (timer1_playing or timer2_playing) else pauseIcon

func update_theme_background():
	var background = get_node_or_null("background")
	if background and has_node("/root/Settings"):
		var settings = get_node("/root/Settings")
		match settings.theme:
			0: background.texture = load("res://images/UI_images/progress_bar/underwater/water_background.png")
			1: background.texture = load("res://images/UI_images/progress_bar/air/Air Background.png")
			2: background.texture = load("res://images/UI_images/progress_bar/land/Land Background.png")

func check_game_end_conditions():
	var timer1 = get_node_or_null("Timer_Label")
	var timer2 = get_node_or_null("Timer_Label2")
	var timeline = get_node_or_null("timeline")
	
	var timer1_expired = timer1 and timer1.get("initialTime") <= 0
	var timer2_expired = timer2 and timer2.get("initialTime") <= 0
	var rounds_completed = timeline and timeline.get("current_round") >= Mitre.timeline_dict.size()
	
	if timer1_expired or timer2_expired or rounds_completed:
		_on_quit_button_pressed()
	
	var window_button = get_node_or_null("Window/Button")
	if window_button:
		window_button.disabled = !sucornah

func handle_debug_input():
	if Input.is_action_just_pressed("ui_accept") and Input.is_key_pressed(KEY_F1):
		toggle_dice_system()

# Game flow control
func disable_attack_buttons(state: bool):
	for button in attackbuttons:
		button.disabled = state
	for card in aCards:
		if card.inPlay:
			card.disable_buttons(state)

func disable_defend_buttons(state: bool):
	for button in defendbuttons:
		button.disabled = state
	for card in dCards:
		card.disable_buttons(state)

# Event handlers
func _on_pause_pressed():
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

func _on_attack_submit_pressed():
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
	if not has_active_defenses():
		return
	
	collapse_all_cards()
	var timer2 = get_node_or_null("Timer_Label2")
	var pause_button = get_node_or_null("Timer_Label/pause")
	
	if timer2:
		timer2.play = false
	disable_defend_buttons(true)
	if pause_button:
		pause_button.disabled = true
	
	# Use dice system directly - show dice popup instead of manual input
	if use_dice_system and has_active_attacks():
		GameData.capture_current_cards(aCards, dCards)
		show_dice_popup()
	else:
		show_manual_input()

# Helper functions
func collapse_all_cards():
	for card in aCards + dCards:
		if card.expanded:
			card.make_small_again()

func has_active_attacks() -> bool:
	for card in aCards:
		if card.card_index != -1:
			return true
	return false

func has_active_defenses() -> bool:
	for card in dCards:
		if card.card_index != -1:
			return true
	return false

func show_manual_input():
	var option_button = get_node_or_null("Window/OptionButton")
	var spin_box = get_node_or_null("Window/SpinBox")
	var window = get_node_or_null("Window")
	
	if option_button:
		option_button.select(-1)
	if spin_box:
		spin_box.value = 0
	if window:
		window.visible = true

# Dice popup system
func show_dice_popup():
	if active_dice_popup:
		return
	
	active_dice_popup = dice_popup_scene.instantiate()
	add_child(active_dice_popup)
	active_dice_popup.z_index = 100
	
	if active_dice_popup.has_signal("dice_completed"):
		active_dice_popup.dice_completed.connect(_on_dice_popup_completed)
	if active_dice_popup.has_signal("dice_cancelled"):
		active_dice_popup.dice_cancelled.connect(_on_dice_popup_cancelled)

func _on_dice_popup_completed(result: int, success: bool):
	if GameData:
		GameData.record_dice_result(result, success)
	
	successornah = "Success" if success else "Failure"
	likelihood = GameData.get_manual_likelihood() if GameData else 50
	sucornah = true
	
	close_dice_popup()
	_on_button_pressed()

func _on_dice_popup_cancelled():
	close_dice_popup()
	show_manual_input()
	disable_defend_buttons(false)
	var pause_button = get_node_or_null("Timer_Label/pause")
	if pause_button:
		pause_button.disabled = false

func close_dice_popup():
	if active_dice_popup:
		active_dice_popup.queue_free()
		active_dice_popup = null

# Manual input handlers
func _on_option_button_item_selected(index):
	successornah = "Success" if index == 0 else "Failure"
	sucornah = true

func _on_spin_box_value_changed(value):
	likelihood = value

func _on_spin_box_2_value_changed(value):
	riskanalysis = value

func _on_var_1_value_changed(value):
	variables[0] = value / 100.0

func _on_var_2_value_changed(value):
	variables[1] = value / 100.0

func _on_var_3_value_changed(value):
	variables[2] = value / 100.0

# Main game logic
func _on_button_pressed():
	if not sucornah:
		return
	
	var row = build_game_data_row()
	save_game_data(row)
	check_for_final_attack()
	
	if finalattack:
		handle_final_attack()
	else:
		continue_normal_flow()
	
	reset_round_state()

func build_game_data_row() -> Array:
	timeTaken = 0
	for card in aCards:
		if card.inPlay:
			timeTaken += card.getTimeValue()
	
	var row = [Time.get_time_string_from_system()]
	
	# Add attack cards
	for card in aCards:
		if card.card_index != -1:
			row.append(card.getString())
			if card.expanded:
				card.make_small_again()
			card.reset_card()
		else:
			row.append("---")
	
	# Add defense cards  
	for card in dCards:
		if card.card_index != -1:
			row.append(card.getString())
			if card.expanded:
				card.make_small_again()
		else:
			row.append("---")
	
	# Add results
	row.append(successornah)
	row.append(likelihood)
	row.append("---")
	
	# Add defense analysis
	for i in range(dCards.size()):
		var card = dCards[i]
		if card.card_index != -1:
			var maturity = card.getMaturityValue()
			var variable = variables[i] if i < variables.size() else 0
			var ASP = 1 - (maturity * 0.2) * variable
			row.append(ASP)
			card.reset_card()
		else:
			row.append("---")
	
	return row

func save_game_data(row: Array):
	var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
	if file:
		file.seek_end()
		file.store_csv_line(row)
		file.close()

func check_for_final_attack():
	finalattack = false
	for card in aCards:
		if card.inPlay and card.card_index != -1:
			var attack_data = Mitre.attack_dict[card.card_index + 1]
			if attack_data.size() > 5 and int(attack_data[5]) == 3:
				finalattack = true
				break

func handle_final_attack():
	load_previous_attacks(save_path)
	var window3 = get_node_or_null("Window3")
	var window = get_node_or_null("Window")
	if window3:
		window3.visible = true
	if window:
		window.visible = false

func continue_normal_flow():
	var window = get_node_or_null("Window")
	var timer1 = get_node_or_null("Timer_Label")
	var pause_button = get_node_or_null("Timer_Label/pause")
	var timeline = get_node_or_null("timeline")
	var attack_dropdown = get_node_or_null("dropdown/attack_option")
	var defend_dropdown = get_node_or_null("dropdown/defend_option")
	
	if window:
		window.visible = false
	disable_attack_buttons(false)
	for card in aCards:
		if card and card.has_method("disable_buttons"):
			card.disable_buttons(true)
	if pause_button:
		pause_button.disabled = false
	if timer1:
		timer1.play = true
	if timeline and timeline.has_method("_progress"):
		timeline._progress(timeTaken * 25)
	if attack_dropdown:
		attack_dropdown.select(-1)
	if defend_dropdown:
		defend_dropdown.select(-1)
	if timeline and timeline.has_method("increase_time"):
		timeline.increase_time()
	timeTaken = 0

func reset_round_state():
	sucornah = false
	finalattack = false
	if GameData:
		GameData.reset_round_data()

# Other handlers
func _on_final_continue_pressed():
	var row = [Time.get_time_string_from_system()]
	for i in range(8):
		row.append("---")
	row.append(riskanalysis)
	save_game_data(row)
	var window3 = get_node_or_null("Window3")
	if window3:
		window3.visible = false
	continue_normal_flow()

func load_previous_attacks(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		file.close()

func _on_end_game_pressed():
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
	if has_node("/root/Music"):
		var music = get_node("/root/Music")
		if music.has_method("mouse_click"):
			music.mouse_click()
	get_tree().change_scene_to_file("res://game_scenes/game_over_screen/game_over.tscn")

func _on_continue_button_pressed():
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
	var window5 = get_node_or_null("Window5")
	if window5:
		window5.visible = true

func _on_window_close_requested():
	var window5 = get_node_or_null("Window5")
	if window5:
		window5.visible = false

func toggle_dice_system():
	use_dice_system = !use_dice_system
	print("Dice system: ", "ENABLED" if use_dice_system else "DISABLED")

func _on_dice_roll_completed():
	if GameData and GameData.dice_roll_completed:
		successornah = "Success" if GameData.last_attack_success else "Failure"
		likelihood = GameData.get_manual_likelihood()
		sucornah = true
		_on_button_pressed()
