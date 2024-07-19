extends Node2D

var aCards
var dCards
var buttons
var attackbuttons
var defendbuttons
var timers
var aPics
var numA = 0
var numD = 0
var save_path ="res://data/info.txt"
var successornah
var likelihood
var currenttimer
var playIcon = preload("res://images/UI_images/play_button.png")
var pauseIcon = preload("res://images/UI_images/pause_button.png")
var round = 1
var starting_time = int(Mitre.timeline_dict[2][0])

# Called when the node enters the scene tree for the first time.
func _ready():
	if Settings.changed_scene == 1:
		$mouse_click.playing = true
		Settings.changed_scene = 0
	aCards = [$a_1, $a_2, $a_3]
	dCards = [$d_1, $d_2, $d_3]
	attackbuttons = [$dropdown/attack_option, $AttackSubmit]
	defendbuttons = [$dropdown/defend_option, $DefenseSubmit]
	timers = [$Timer_Label, $Timer_Label2]
	$a_1.cardType = "a"
	$a_2.cardType = "a"
	$a_3.cardType = "a"
	$d_1.cardType = "d"
	$d_2.cardType = "d"
	$d_3.cardType = "d"
	currenttimer = 0
	var file = FileAccess.open(save_path,FileAccess.WRITE)
	file.close()
	disable_attack_buttons(true)
	disable_defend_buttons(true)
	$Timer_Label/pause.disabled = true
	$Window.visible = false
	$EndGame.visible = false
	var initialTime = $Timer_Label.initialTime
	var minutes = int(initialTime) / 60
	var seconds = int(initialTime) % 60
	if seconds < 10:
		$Timer_Label.text = str(minutes) + ":0" + str(seconds)
	else:
		$Timer_Label.text = str(minutes) + ":" + str(seconds)
	initialTime = $Timer_Label2.initialTime
	minutes = int(initialTime) / 60
	seconds = int(initialTime) % 60
	if seconds < 10:
		$Timer_Label2.text = str(minutes) + ":0" + str(seconds)
	else:
		$Timer_Label2.text = str(minutes) + ":" + str(seconds)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for card in aCards:
		if card.reset_dropdown:
			$dropdown/attack_option.select(-1)
			card.reset_dropdown = false
			
	if $dropdown.generateACard:
		for card in aCards:
			if $dropdown.generateACard:
				if !card.inPlay:
					card.setCard($dropdown.attack_choice)
					card.setText($dropdown.attack_choice)
					card.setTimeImage()
					card.setTimeValue("10 minutes")
					card.setCost(2)
					card.play()
					$dropdown.generateACard = false
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()
	if $dropdown.generateDCard && numD < 3:		
		dCards[numD].visible = true
		$dropdown.generateDCard = false
		numD += 1
	
	if $Timer_Label.play == true:
		currenttimer = 0
	elif $Timer_Label2.play == true:
		currenttimer = 1
	
	if $Timer_Label.play == true || $Timer_Label2.play == true:
		$Timer_Label/pause.icon = pauseIcon
	else:
		$Timer_Label/pause.icon = playIcon
	
	if $Timer_Label.initialTime <= 0 || $Timer_Label2.initialTime <= 0 || $timeline.timelabel > int(Mitre.timeline_dict[Mitre.timeline_dict.size()-1][0]):
		_on_end_game_pressed()

func disable_attack_buttons(state):
	for button in attackbuttons:
		button.disabled = state
	for card in aCards:
		card.disable_buttons(state)

func disable_defend_buttons(state):
	for button in defendbuttons:
		button.disabled = state
	for card in dCards:
		card.disable_buttons(state)

func _on_pause_pressed():
	if currenttimer == 0:
		$Timer_Label.play = !$Timer_Label.play
		if !$Timer_Label.play:
			disable_attack_buttons(true)
			disable_defend_buttons(true)
		else:
			disable_attack_buttons(false)
	elif currenttimer == 1:
		$Timer_Label2.play = !$Timer_Label2.play
		if !$Timer_Label2.play:
			disable_attack_buttons(true)
			disable_defend_buttons(true)
		else:
			disable_defend_buttons(false)

func _on_start_game_pressed():
	$Timer_Label.play = true
	disable_attack_buttons(false)
	$Timer_Label/pause.disabled = false
	$StartGame.visible = false
	$EndGame.visible = true

func _on_end_game_pressed():
	Settings.changed_scene = 1
	get_tree().change_scene_to_file("res://game_scenes/game_over_screen/game_over.tscn")
	hide ()

func _on_attack_submit_pressed():
	$Timer_Label.play = false
	$Timer_Label2.play = true
	disable_attack_buttons(true)
	disable_defend_buttons(false)
	$DefenseSubmit.disabled = false

func _on_defense_submit_pressed():
	$Timer_Label2.play = false
	disable_defend_buttons(true)
	$Timer_Label/pause.disabled = true
	$Window/OptionButton.select(-1)
	$Window/SpinBox.value = 0
	$Window.visible = true

func _on_option_button_item_selected(index):
	if index==0:
		successornah="Success"
	else:
		successornah="Failure"

func _on_spin_box_value_changed(value):
	likelihood=value

func _on_button_pressed():
	var row=[Time.get_time_string_from_system()]
	for card in aCards:
		if card.card_index != -1:
			row += [Mitre.attack_dict[card.card_index][2]]
			card.reset_card()
	row += [successornah]
	row += [likelihood]
	var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
	file.seek_end()
	file.store_csv_line(row)
	file.close()
	$timeline.submitted = false
	print("hehehaw")
	$Window.visible = false
	disable_attack_buttons(false)
	$Timer_Label/pause.disabled = false
	$Timer_Label.play = true
	$timeline._progress((int(Mitre.timeline_dict[round+2][0]) - starting_time)*150)
	print((int(Mitre.timeline_dict[round+2][0]) - starting_time)*150)
	starting_time = (int(Mitre.timeline_dict[round+2][0]))
	$dropdown/attack_option.select(-1)
	$dropdown/defend_option.select(-1)	
	round += 1
	
