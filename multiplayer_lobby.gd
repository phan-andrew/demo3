# SEACAT Multiplayer Lobby - Manual start with player list
extends Control

@onready var firebase_manager = get_node("/root/FirebaseManager")

# Variables for player setup
var player_name = "Player"
var selected_team = 0  # 0 = Red, 1 = Blue
var room_code_entered = ""

# UI nodes
@onready var create_room_btn = $CreateRoomButton
@onready var join_room_btn = $JoinRoomButton
@onready var name_setup_btn = $NameSetupButton
@onready var team_btn = $TeamButton
@onready var back_btn = $BackButton
@onready var status_label = $StatusLabel
@onready var room_code_display = $RoomCodeDisplay

# Lobby state
var current_players = {}
var room_created = false
var room_joined = false

# UI References that will be created
var player_list_container
var start_game_btn

func _ready():
	# Set dynamic background based on theme
	$Sprite2D2.texture = load(Settings.textured[Settings.theme])
	
	# Connect buttons
	create_room_btn.pressed.connect(_on_create_room_pressed)
	join_room_btn.pressed.connect(_on_join_room_pressed)
	name_setup_btn.pressed.connect(_on_name_setup_pressed)
	team_btn.pressed.connect(_on_team_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	
	# Connect Firebase signals
	if firebase_manager:
		firebase_manager.room_created.connect(_on_room_created)
		firebase_manager.room_joined.connect(_on_room_joined)
		firebase_manager.game_state_changed.connect(_on_game_state_changed)
		firebase_manager.connection_error.connect(_on_firebase_error)
	
	# Initial UI state
	room_code_display.visible = false
	update_team_button_text()
	status_label.text = "Set your name and team, then create or join a room"
	
	# Create lobby UI elements
	create_lobby_ui()
	
	# Create reusable input dialog
	create_input_dialog()

func create_lobby_ui():
	"""Create the lobby UI with player list and start button"""
	# Create player list container
	player_list_container = VBoxContainer.new()
	player_list_container.name = "PlayerListContainer"
	player_list_container.position = Vector2(200, 550)
	player_list_container.size = Vector2(750, 150)
	player_list_container.visible = false
	add_child(player_list_container)
	
	# Add title for player list
	var list_title = Label.new()
	list_title.text = "PLAYERS IN LOBBY:"
	list_title.theme = load("res://pixel font/mid_font_theme.tres")
	list_title.theme_override_font_sizes["font_size"] = 18
	list_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_list_container.add_child(list_title)
	
	# Create start game button
	start_game_btn = Button.new()
	start_game_btn.name = "StartGameButton"
	start_game_btn.position = Vector2(400, 650)
	start_game_btn.size = Vector2(350, 75)
	start_game_btn.theme = load("res://pixel font/mid_font_theme.tres")
	start_game_btn.text = "START GAME"
	start_game_btn.visible = false
	start_game_btn.pressed.connect(_on_start_game_pressed)
	add_child(start_game_btn)

func create_input_dialog():
	"""Create a reusable input dialog"""
	var input_dialog = AcceptDialog.new()
	input_dialog.name = "InputDialog"
	input_dialog.title = "Input Required"
	input_dialog.size = Vector2(400, 200)
	input_dialog.theme = load("res://pixel font/mid_font_theme.tres")
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	
	var instruction_label = Label.new()
	instruction_label.name = "InstructionLabel"
	instruction_label.text = "Enter value:"
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instruction_label)
	
	var input_line_edit = LineEdit.new()
	input_line_edit.name = "InputLineEdit"
	input_line_edit.placeholder_text = "Type here..."
	input_line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(input_line_edit)
	
	input_dialog.add_child(vbox)
	add_child(input_dialog)

func _on_name_setup_pressed():
	Music.mouse_click()
	var new_name = await get_player_name_input()
	if new_name.length() > 0:
		player_name = new_name
		name_setup_btn.text = "NAME: " + player_name

func _on_team_pressed():
	Music.mouse_click()
	selected_team = 1 - selected_team
	update_team_button_text()

func update_team_button_text():
	if selected_team == 0:
		team_btn.text = "TEAM: RED (ATTACK)"
	else:
		team_btn.text = "TEAM: BLUE (DEFENSE)"

func _on_create_room_pressed():
	Music.mouse_click()
	
	if player_name == "Player":
		status_label.text = "Please set your name first"
		return
	
	status_label.text = "Creating room..."
	create_room_btn.disabled = true
	join_room_btn.disabled = true
	
	var team_name = "red" if selected_team == 0 else "blue"
	firebase_manager.create_room(player_name, team_name)

func _on_join_room_pressed():
	Music.mouse_click()
	
	if player_name == "Player":
		status_label.text = "Please set your name first"
		return
	
	var code = await get_room_code_input()
	if code.length() == 6:
		status_label.text = "Joining room " + code + "..."
		join_room_btn.disabled = true
		create_room_btn.disabled = true
		
		var team_name = "red" if selected_team == 0 else "blue"
		firebase_manager.join_room(code, player_name, team_name)
	elif code.length() > 0:
		status_label.text = "Room code must be 6 characters"
	else:
		status_label.text = "Room code entry cancelled"

func _on_back_pressed():
	Music.mouse_click()
	if firebase_manager:
		firebase_manager.stop_syncing()
	get_tree().change_scene_to_file("res://game_scenes/start_screen/start_screen.tscn")
	hide()

func _on_room_created(code: String):
	room_code_display.text = "Room Code: " + code + "\nShare this code with other player"
	room_code_display.visible = true
	status_label.text = "Room created! Waiting for players..."
	room_created = true
	
	# Show lobby UI
	show_lobby_ui()
	
	# Re-enable join button
	join_room_btn.disabled = false

func _on_room_joined(code: String):
	status_label.text = "Joined room " + code + "!"
	room_joined = true
	
	# Show lobby UI
	show_lobby_ui()

func _on_game_state_changed(new_state: Dictionary):
	"""Handle real-time game state updates"""
	var players = new_state.get("players", {})
	update_player_list(players)

func update_player_list(players: Dictionary):
	"""Update the visual player list"""
	current_players = players
	
	# Clear existing player displays (except title)
	for child in player_list_container.get_children():
		if child.name != "Label":  # Don't remove the title
			child.queue_free()
	
	# Add current players
	for player_id in players:
		var player_data = players[player_id]
		var player_display = Label.new()
		
		var display_text = "• " + player_data.get("name", "Unknown")
		display_text += " (" + player_data.get("team", "unknown").to_upper() + " TEAM)"
		
		if player_data.get("is_host", false):
			display_text += " [HOST]"
		
		player_display.text = display_text
		player_display.theme = load("res://pixel font/mid_font_theme.tres")
		player_display.theme_override_font_sizes["font_size"] = 16
		player_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Color code by team
		if player_data.get("team", "") == "red":
			player_display.theme_override_colors["font_color"] = Color(1, 0.3, 0.3, 1)  # Red
		else:
			player_display.theme_override_colors["font_color"] = Color(0.3, 0.5, 1, 1)  # Blue
		
		player_list_container.add_child(player_display)
	
	# Update status and start button
	var player_count = players.size()
	if player_count >= 2:
		status_label.text = "Ready to start! " + str(player_count) + " players connected"
		
		# Only host can start the game
		if firebase_manager and firebase_manager.is_host:
			start_game_btn.visible = true
			start_game_btn.text = "START GAME (" + str(player_count) + " PLAYERS)"
		else:
			start_game_btn.visible = false
			status_label.text += " - Waiting for host to start..."
	else:
		status_label.text = "Waiting for more players... (" + str(player_count) + "/2)"
		start_game_btn.visible = false

func show_lobby_ui():
	"""Show the lobby interface"""
	player_list_container.visible = true
	
	# Hide setup buttons
	create_room_btn.visible = false
	name_setup_btn.visible = false
	team_btn.visible = false

func _on_start_game_pressed():
	"""Start the multiplayer game"""
	Music.mouse_click()
	
	if current_players.size() < 2:
		status_label.text = "Need at least 2 players to start!"
		return
	
	status_label.text = "Starting game..."
	start_game_btn.disabled = true
	
	# Optional: Update game state to "starting" in Firebase
	if firebase_manager:
		firebase_manager.sync_phase_change("game_starting")
	
	# Transition to game
	await get_tree().create_timer(1.0).timeout
	start_multiplayer_game()

func start_multiplayer_game():
	"""Transition to the multiplayer game"""
	if firebase_manager:
		firebase_manager.multiplayer_enabled = true
	
	get_tree().change_scene_to_file("res://game_scenes/good_screen/game_screen.tscn")

# INPUT METHODS
func get_player_name_input() -> String:
	"""Get player name via input dialog"""
	var input_dialog = get_node("InputDialog")
	var instruction_label = input_dialog.get_node("VBoxContainer/InstructionLabel")
	var input_line_edit = input_dialog.get_node("VBoxContainer/InputLineEdit")
	
	input_dialog.title = "Enter Player Name"
	instruction_label.text = "Enter your player name:"
	input_line_edit.text = ""
	input_line_edit.placeholder_text = "Your name..."
	input_line_edit.max_length = 20
	
	input_dialog.popup_centered()
	input_line_edit.grab_focus()
	
	await input_dialog.confirmed
	
	var result = input_line_edit.text.strip_edges()
	return result

func get_room_code_input() -> String:
	"""Get room code via input dialog"""
	var input_dialog = get_node("InputDialog")
	var instruction_label = input_dialog.get_node("VBoxContainer/InstructionLabel")
	var input_line_edit = input_dialog.get_node("VBoxContainer/InputLineEdit")
	
	input_dialog.title = "Enter Room Code"
	instruction_label.text = "Enter 6-character room code:"
	input_line_edit.text = ""
	input_line_edit.placeholder_text = "ABC123"
	input_line_edit.max_length = 6
	
	input_dialog.popup_centered()
	input_line_edit.grab_focus()
	
	await input_dialog.confirmed
	
	var result = input_line_edit.text.strip_edges().to_upper()
	return result

# ERROR HANDLING
func _on_firebase_error(error_message: String):
	"""Handle Firebase connection errors"""
	status_label.text = "Error: " + error_message
	create_room_btn.disabled = false
	join_room_btn.disabled = false
	room_code_display.visible = false
	player_list_container.visible = false
	start_game_btn.visible = false
