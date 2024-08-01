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
var save_path ="res://data/game_data.txt"
var successornah
var sucornah = false
var likelihood = 0
var riskanalysis = 0
var currenttimer
var playIcon = preload("res://images/UI_images/play_button.png")
var pauseIcon = preload("res://images/UI_images/pause_button.png")
var round = 1
var card_expanded=-1
var finalattack = false
var biggest = 0
var attackstringstart = ": $"
var attackstringmid = ", "
var attackstringend = " minutes"
var defendstringstart = ": "
var defendstringend = " stars"

func _ready():
	aCards = [$a_1, $a_2, $a_3]
	dCards = [$d_1, $d_2, $d_3]
	attackbuttons = [$dropdown/attack_option, $AttackSubmit]
	defendbuttons = [$dropdown/defend_option, $DefenseSubmit]
	timers = [$Timer_Label, $Timer_Label2]
	$a_1.cardType = "a"
	$a_1/card/card_back.frame = 4
	$a_2.cardType = "a"
	$a_2/card/card_back.frame = 4
	$a_3.cardType = "a"
	$a_3/card/card_back.frame = 4
	$d_1.cardType = "d"
	$d_1/card/card_back.frame = 3
	$d_2.cardType = "d"
	$d_2/card/card_back.frame = 3
	$d_3.cardType = "d"
	$d_3/card/card_back.frame = 3
	currenttimer = 0
	var file = FileAccess.open(save_path,FileAccess.WRITE)
	file.store_csv_line(["Time","Attack 1","Attack 2", "Attack 3","Defense 1", "Defense 2", "Defense 3", "Attack Success","Attack Success Likelihood","Risk Analysis"])
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
	Music.play_music()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for card in aCards:
		if card.reset_dropdown:
			$dropdown/attack_option.select(-1)
			card.reset_dropdown = false
			
	for card in dCards:
		if card.reset_dropdown:
			$dropdown/defend_option.select(-1)
			card.reset_dropdown = false
	
	if $dropdown.generateACard:
		for card in aCards:
			if $dropdown.generateACard:
				if !card.inPlay:
					card.setCard(int(Mitre.opforprof_dict[$dropdown.attack_choice+2][0]))
					card.setText(int(Mitre.opforprof_dict[$dropdown.attack_choice+2][0]))
					card.setTimeImage()
					card.setTimeValue(int(Mitre.opforprof_dict[$dropdown.attack_choice+2][2]))
					card.setCost(int(Mitre.opforprof_dict[$dropdown.attack_choice+2][1]))
					card.play()
					$dropdown.generateACard = false
	if $a_1.expanded:
		alock_expands(0)
	if $a_2.expanded:
		alock_expands(1)
	if $a_3.expanded:
		alock_expands(2)
	else:
		areset_expands()
	if $dropdown.generateDCard:
		for card in dCards:
			if $dropdown.generateDCard:
				if !card.inPlay:
					card.setCard(Mitre.d3fendprof_dict[$dropdown.defend_choice+2][0])
					card.setText(Mitre.d3fendprof_dict[$dropdown.defend_choice+2][0])
					card.setMaturity(int(Mitre.d3fendprof_dict[$dropdown.defend_choice+2][1]))
					card.play()
					$dropdown.generateDCard = false
	if $d_1.expanded:
		dlock_expands(0)
	if $d_2.expanded:
		dlock_expands(1)
	if $d_3.expanded:
		dlock_expands(2)
	else:
		dreset_expands()			
					
	if Input.is_action_just_pressed("exit"):
		get_tree().quit()

	
	if $Timer_Label.play == true:
		currenttimer = 0
	elif $Timer_Label2.play == true:
		currenttimer = 1
	
	if $Timer_Label.play == true || $Timer_Label2.play == true:
		$Timer_Label/pause.icon = pauseIcon
	else:
		$Timer_Label/pause.icon = playIcon
	
	if $Timer_Label.initialTime <= 0 || $Timer_Label2.initialTime <= 0 || $timeline.timelabel > int(Mitre.timeline_dict[Mitre.timeline_dict.size()-2][0]):
		_on_quit_button_pressed()
		
	if Settings.theme == 0:
		$background.texture = load("res://images/UI_images/progress_bar/underwater/water_background.png")
	$Window/Button.disabled = !sucornah

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
	$Window4.visible = false
	$EndGame.visible = true

func _on_end_game_pressed():
	_on_pause_pressed()
	$EndGame.disabled = true
	$Timer_Label/pause.disabled = true
	$Window2.visible=true
	
func _on_quit_button_pressed():
		Music.mouse_click()
		get_tree().change_scene_to_file("res://game_scenes/game_over_screen/game_over.tscn")
		hide()

func _on_continue_button_pressed():
	_on_pause_pressed()
	$EndGame.disabled = false
	$Timer_Label/pause.disabled = false
	$Window2.visible=false

func _on_attack_submit_pressed():
	var attackpresent = false
	for card in aCards:
		if card.card_index != -1:
			attackpresent = true
		if card.expanded:	
			card.make_small_again()
	for card in dCards:
		if card.expanded:
			card.make_small_again()
	if attackpresent:
		$Timer_Label.play = false
		$Timer_Label2.play = true
		disable_attack_buttons(true)
		disable_defend_buttons(false)
		$DefenseSubmit.disabled = false


func _on_defense_submit_pressed():
	var defensepresent = false
	for card in dCards:
		if card.card_index != -1:
			defensepresent = true
		if card.expanded:
			card.make_small_again()
	for card in aCards:
		if card.expanded:	
			card.make_small_again()
	if defensepresent:
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
	sucornah = true

func _on_spin_box_value_changed(value):
	likelihood=value

func _on_spin_box_2_value_changed(value):
	riskanalysis=value

func _on_button_pressed():
	if sucornah:
		for card in aCards:
			if card.getTimeValue() > biggest:
				biggest = card.getTimeValue()
		
		var row=[Time.get_time_string_from_system()]
		for card in aCards:
			if card.card_index != -1:
				row += [card.getString()]
				card.reset_card()
			else:
				row+=["---"]
		for card in dCards:
			if card.card_index != -1:
				row+=[card.getString()]
				card.reset_card()
			else:
				row+=["---"]
		row += [successornah]
		row += [likelihood]
		row += ["---"]
		var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
		file.seek_end()
		file.store_csv_line(row)
		file.close()
		for card in aCards:
			if int(Mitre.attack_dict[int(Mitre.opforprof_dict[$dropdown.attack_choice+2][0])+1][5]) == 3:
				finalattack = true
		
		if finalattack:
			load_previous_attacks("res://data/game_data.txt")
			$Window3.visible  = true
			$Window.visible = false
		else:
			$timeline.submitted = false
			$Window.visible = false
			disable_attack_buttons(false)
			$Timer_Label/pause.disabled = false
			$Timer_Label.play = true
			$timeline._progress(biggest * 150)

			$dropdown/attack_option.select(-1)
			$dropdown/defend_option.select(-1)	
			round += 1
			$timeline.timelabel += biggest
			biggest = 0
		sucornah = false
		finalattack = false

func _on_final_continue_pressed():
	var row=[Time.get_time_string_from_system()]
	for i in range(8):
		row += ["---"]
	row += [riskanalysis]
	var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
	file.seek_end()
	file.store_csv_line(row)
	file.close()
	$timeline.submitted = false
	$Window3.visible = false
	disable_attack_buttons(false)
	$Timer_Label/pause.disabled = false
	$Timer_Label.play = true
	$dropdown/attack_option.select(-1)
	$dropdown/defend_option.select(-1)
	$timeline._progress(biggest * 150)
	$timeline.timelabel += biggest
	round += 1
	biggest = 0

func load_previous_attacks(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var formatted_text = format_csv(content)
		$Window3/TextEdit.text = formatted_text

func format_csv(content):
	var rows = content.split("\n")
	var columns = []
	
	for row in rows:
		var cells = row.split(",")
		columns.append(cells)

	var col_width = []
	for i in range(columns[0].size()):
		if i != 2 && i != 3 && i != 5 && i != 6:
			var max_width = 0
			for row in columns:
				if i != 1 && i != 4:
					if(row.size() > 1):
						if row[i].length() > max_width:
							max_width = row[i].length()
				else:
					if(row.size()>1):
						for j in range(3):
							if row[i+j].length() > max_width:
								max_width = row[i+j].length()
			col_width.append(max_width)
		else:
			col_width.append(0)
	var formatted_text = ""
	for row in columns:
		if row.size() > 1:
			for i in range(row.size()):
				if i != 2 && i != 3 && i != 5 && i != 6:
					var cell = row[i]
					formatted_text += pad_string(cell, col_width[i] + 5)
			if row[9] == "---":
				formatted_text += "\n"
				formatted_text += pad_string("", col_width[0] + 5)
				formatted_text += pad_string(row[2], col_width[1] + 5)
				formatted_text += pad_string(row[5], col_width[4] + 5)
				formatted_text += pad_string("", col_width[7] + 5)
				formatted_text += pad_string("", col_width[8] + 5)
				formatted_text += pad_string("", col_width[9] + 5)
				formatted_text += "\n"
				formatted_text += pad_string("", col_width[0] + 5)
				formatted_text += pad_string(row[3], col_width[1] + 5)
				formatted_text += pad_string(row[6], col_width[4] + 5)
				formatted_text += pad_string("", col_width[7] + 5)
				formatted_text += pad_string("", col_width[8] + 5)
				formatted_text += pad_string("", col_width[9] + 5)
		formatted_text += "\n"
		formatted_text += "\n"
	
	return formatted_text

func pad_string(text: String, width: int):
	var padded_text = text
	while padded_text.length() < width:
		padded_text += " "
	return padded_text

func alock_expands(expanded):
	if expanded==0:
		$a_2.disable_expand(true)
		$a_3.disable_expand(true)
	if expanded==1:
		$a_1.disable_expand(true)
		$a_3.disable_expand(true)
	if expanded==2:
		$a_1.disable_expand(true)
		$a_2.disable_expand(true)
func areset_expands():
	for card in aCards:
		card.disable_expand(false)
		
func dlock_expands(expanded):
	if expanded==0:
		$d_2.disable_expand(true)
		$d_3.disable_expand(true)
	if expanded==1:
		$d_1.disable_expand(true)
		$d_3.disable_expand(true)
	if expanded==2:
		$d_1.disable_expand(true)
		$d_2.disable_expand(true)
func dreset_expands():
	for card in dCards:
		card.disable_expand(false)

func _on_help_pressed():
	$Window5.visible = true

func _on_window_close_requested():
	$Window5.visible = false
