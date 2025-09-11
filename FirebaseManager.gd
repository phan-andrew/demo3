# FirebaseManager.gd - Enhanced Firebase integration with better error handling
extends Node

# Your actual Firebase database URL
var FIREBASE_URL = "https://seacat-65db8-default-rtdb.firebaseio.com/"

# Game state
var room_code = ""
var player_id = ""
var player_team = "" # "red", "blue", or "spectator"
var is_host = false
var multiplayer_enabled = false

# HTTP requests
var http_request: HTTPRequest
var poll_timer: Timer

# Sync state
var last_known_state = {}
var sync_enabled = false
var connection_attempts = 0
var max_connection_attempts = 5

# Signals
signal room_created(code)
signal room_joined(code) 
signal game_state_changed(new_state)
signal card_played_by_opponent(team, position, card_data)
signal phase_changed(new_phase)
signal connection_error(message)
signal players_updated(players_dict)

func _ready():
	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# Create polling timer for real-time updates
	poll_timer = Timer.new()
	poll_timer.wait_time = 2.0  # Check every 2 seconds for better responsiveness
	poll_timer.timeout.connect(_poll_firebase)
	add_child(poll_timer)
	
	# Generate unique player ID (Firebase-safe - no periods allowed)
	var timestamp = str(int(Time.get_unix_time_from_system()))  # Remove decimal
	var random_num = str(randi() % 10000)  # 4-digit random number
	player_id = "player_" + timestamp + "_" + random_num
	print("🔥 Firebase Manager ready. Player ID: ", player_id)

# ROOM MANAGEMENT
func create_room(host_name: String, host_team: String = "red") -> String:
	"""Create a new multiplayer room"""
	room_code = generate_room_code()
	player_team = host_team
	is_host = true
	connection_attempts = 0
	
	var initial_state = {
		"room_info": {
			"host_id": player_id,
			"host_name": host_name,
			"created": Time.get_unix_time_from_system(),
			"status": "waiting",
			"version": 1
		},
		"players": {
			player_id: {
				"name": host_name,
				"team": host_team,
				"ready": false,
				"last_seen": Time.get_unix_time_from_system(),
				"is_host": true
			}
		},
		"game_state": {
			"phase": "attack_phase",  # Start with attack phase
			"round": 1,
			"attack_cards": {},
			"defense_cards": {},
			"position_states": {
				"0": "EMPTY",
				"1": "EMPTY", 
				"2": "EMPTY"
			},
			"last_dice_results": [],
			"last_updated": Time.get_unix_time_from_system()
		}
	}
	
	# Upload to Firebase
	var url = FIREBASE_URL + "rooms/" + room_code + ".json"
	var headers = ["Content-Type: application/json"]
	var data = JSON.stringify(initial_state)
	
	print("🔥 Creating room: ", room_code)
	var error = http_request.request(url, headers, HTTPClient.METHOD_PUT, data)
	
	if error != OK:
		emit_signal("connection_error", "Failed to create room: " + str(error))
		return ""
	
	emit_signal("room_created", room_code)
	start_syncing()
	
	return room_code

func join_room(code: String, player_name: String, team: String = "blue"):
	"""Join an existing room"""
	room_code = code.to_upper()
	player_team = team
	is_host = false
	connection_attempts = 0
	
	# First, check if room exists
	check_room_exists(room_code, player_name, team)

func check_room_exists(code: String, player_name: String, team: String):
	"""Check if room exists before joining"""
	var url = FIREBASE_URL + "rooms/" + code + ".json"
	var headers = []
	
	# Create a separate request for checking
	var check_request = HTTPRequest.new()
	add_child(check_request)
	check_request.request_completed.connect(_on_room_check_completed.bind(check_request, player_name, team))
	check_request.request(url, headers, HTTPClient.METHOD_GET)

func _on_room_check_completed(check_request: HTTPRequest, player_name: String, team: String, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Handle room existence check"""
	check_request.queue_free()
	
	if response_code != 200:
		emit_signal("connection_error", "Room not found or connection failed")
		return
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK or json.data == null:
		emit_signal("connection_error", "Invalid room data")
		return
	
	var room_data = json.data
	if not room_data.has("room_info"):
		emit_signal("connection_error", "Room is invalid or corrupted")
		return
	
	# Room exists, now join it
	actually_join_room(player_name, team)

func actually_join_room(player_name: String, team: String):
	"""Actually join the room after verification"""
	var player_data = {
		"name": player_name,
		"team": team,
		"ready": false,
		"last_seen": Time.get_unix_time_from_system(),
		"is_host": false
	}
	
	var url = FIREBASE_URL + "rooms/" + room_code + "/players/" + player_id + ".json"
	var headers = ["Content-Type: application/json"]
	var data = JSON.stringify(player_data)
	
	print("🔥 Joining room: ", room_code, " as ", team, " team")
	var error = http_request.request(url, headers, HTTPClient.METHOD_PUT, data)
	
	if error != OK:
		emit_signal("connection_error", "Failed to join room: " + str(error))
		return
	
	emit_signal("room_joined", room_code)
	start_syncing()

func start_syncing():
	"""Start real-time sync polling"""
	sync_enabled = true
	poll_timer.start()
	print("🔄 Real-time sync started")

func stop_syncing():
	"""Stop real-time sync"""
	sync_enabled = false
	poll_timer.stop()
	room_code = ""
	last_known_state = {}
	print("⏹️ Real-time sync stopped")

# REAL-TIME POLLING
func _poll_firebase():
	"""Poll Firebase for updates"""
	if not sync_enabled or room_code == "":
		return
	
	# Update heartbeat
	update_player_heartbeat()
	
	var url = FIREBASE_URL + "rooms/" + room_code + ".json"
	var headers = []
	
	# Use a separate request for polling to avoid conflicts
	var poll_request = HTTPRequest.new()
	add_child(poll_request)
	poll_request.request_completed.connect(_on_poll_completed.bind(poll_request))
	poll_request.request(url, headers, HTTPClient.METHOD_GET)

func update_player_heartbeat():
	"""Update player's last_seen timestamp"""
	if not sync_enabled or room_code == "":
		return
	
	var url = FIREBASE_URL + "rooms/" + room_code + "/players/" + player_id + "/last_seen.json"
	var headers = ["Content-Type: application/json"]
	var timestamp = str(Time.get_unix_time_from_system())
	
	# Use a quick request for heartbeat
	var heartbeat_request = HTTPRequest.new()
	add_child(heartbeat_request)
	heartbeat_request.request_completed.connect(_on_heartbeat_completed.bind(heartbeat_request))
	heartbeat_request.request(url, headers, HTTPClient.METHOD_PUT, timestamp)

func _on_heartbeat_completed(heartbeat_request: HTTPRequest, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Handle heartbeat response"""
	heartbeat_request.queue_free()
	# Don't need to do anything - just keeping connection alive

func _on_poll_completed(poll_request: HTTPRequest, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Handle polling response"""
	poll_request.queue_free()
	
	if response_code != 200:
		connection_attempts += 1
		if connection_attempts >= max_connection_attempts:
			emit_signal("connection_error", "Lost connection to server")
			stop_syncing()
		return
	
	connection_attempts = 0  # Reset on successful connection
	
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	if parse_result != OK or json.data == null:
		return
	
	var new_state = json.data
	
	# Check if state actually changed
	if hash(var_to_str(new_state)) == hash(var_to_str(last_known_state)):
		return
	
	process_state_changes(new_state)
	last_known_state = new_state
	emit_signal("game_state_changed", new_state)

func process_state_changes(new_state: Dictionary):
	"""Process specific state changes"""
	var game_state = new_state.get("game_state", {})
	var players = new_state.get("players", {})
	
	# Emit players update
	emit_signal("players_updated", players)
	
	# Check for new cards played by opponents
	check_opponent_cards("attack_cards", game_state)
	check_opponent_cards("defense_cards", game_state)
	
	# Check for phase changes
	var current_phase = game_state.get("phase", "waiting")
	var old_phase = last_known_state.get("game_state", {}).get("phase", "waiting")
	if current_phase != old_phase:
		emit_signal("phase_changed", current_phase)

func check_opponent_cards(card_type: String, game_state: Dictionary):
	"""Check for cards played by opponents"""
	var new_cards = game_state.get(card_type, {})
	var old_cards = last_known_state.get("game_state", {}).get(card_type, {})
	
	for position_str in new_cards:
		if not old_cards.has(position_str):
			var card_data = new_cards[position_str]
			var played_by = card_data.get("played_by", "")
			var player_team_who_played = card_data.get("player_team", "")
			
			if played_by != player_id and player_team_who_played != player_team:
				var position = int(position_str)
				emit_signal("card_played_by_opponent", player_team_who_played, position, card_data)

# GAME STATE SYNC
func sync_card_play(card_type: String, position: int, card_data: Dictionary):
	"""Sync card play to Firebase"""
	if not sync_enabled:
		return
	
	var sync_data = card_data.duplicate()
	sync_data["played_by"] = player_id
	sync_data["played_at"] = Time.get_unix_time_from_system()
	sync_data["player_team"] = player_team
	
	var url = FIREBASE_URL + "rooms/" + room_code + "/game_state/" + card_type + "_cards/" + str(position) + ".json"
	var headers = ["Content-Type: application/json"]
	var data = JSON.stringify(sync_data)
	
	http_request.request(url, headers, HTTPClient.METHOD_PUT, data)
	print("🔄 Synced ", card_type, " card at position ", position + 1)

func sync_phase_change(new_phase: String):
	"""Sync game phase change"""
	if not sync_enabled or not is_host:
		return
	
	var url = FIREBASE_URL + "rooms/" + room_code + "/game_state/phase.json"
	var headers = ["Content-Type: application/json"]
	
	http_request.request(url, headers, HTTPClient.METHOD_PUT, '"' + new_phase + '"')
	print("🔄 Phase changed to: ", new_phase)

# UTILITY FUNCTIONS
func generate_room_code() -> String:
	"""Generate a 6-character room code"""
	var chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var code = ""
	for i in range(6):
		code += chars[randi() % chars.length()]
	return code

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	"""Handle HTTP request completion"""
	if response_code == 200:
		print("✅ Firebase request successful")
	else:
		print("❌ Firebase request failed: ", response_code)
		if body.size() > 0:
			print("Error details: ", body.get_string_from_utf8())

# PUBLIC API FUNCTIONS
func get_current_phase() -> String:
	"""Get current game phase"""
	return last_known_state.get("game_state", {}).get("phase", "waiting")

func is_my_turn() -> bool:
	"""Check if it's current player's turn"""
	var phase = get_current_phase()
	match phase:
		"attack_phase":
			return player_team == "red"
		"defense_phase":
			return player_team == "blue"
		_:
			return false

func get_room_players() -> Dictionary:
	"""Get all players in the room"""
	return last_known_state.get("players", {})

func set_player_ready(ready: bool):
	"""Set current player ready status"""
	var url = FIREBASE_URL + "rooms/" + room_code + "/players/" + player_id + "/ready.json"
	var headers = ["Content-Type: application/json"]
	
	http_request.request(url, headers, HTTPClient.METHOD_PUT, "true" if ready else "false")

func get_connection_status() -> String:
	"""Get current connection status"""
	if not sync_enabled:
		return "disconnected"
	elif connection_attempts > 0:
		return "reconnecting"
	else:
		return "connected"
