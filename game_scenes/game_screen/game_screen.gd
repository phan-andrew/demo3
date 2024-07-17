extends Node2D

var aCards
var dCards
var buttons
var attackbuttons
var defendbuttons
var aPics
var numA = 0
var numD = 0
var save_path ="res://data/info.txt"


# Called when the node enters the scene tree for the first time.
func _ready():
	aCards = [$a_1, $a_2, $a_3]
	dCards = [$d_1, $d_2, $d_3]
	buttons = [$timeline/submit_button]
	attackbuttons = [$dropdown/attack_option, $AttackSubmit]
	defendbuttons = [$dropdown/defend_option, $DefenseSubmit]
	$a_1.cardType = "a"
	$a_2.cardType = "a"
	$a_3.cardType = "a"
	$d_1.cardType = "d"
	$d_2.cardType = "d"
	$d_3.cardType = "d"
	var file = FileAccess.open(save_path,FileAccess.WRITE)
	file.close()
	disable_attack_buttons(true)
	disable_defend_buttons(true)

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
					
	if $dropdown.generateDCard && numD < 3:		
		dCards[numD].visible = true
		$dropdown.generateDCard = false
		numD += 1
		
	if $timeline.submitted == true:
		var row=[Time.get_time_string_from_system()]
		for card in aCards:
			if card.card_index != -1:
				row += [Mitre.attack_dict[card.card_index][2]]
		var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
		file.seek_end()
		file.store_csv_line(row)
		file.close()
		$timeline.submitted = false
		print("hehehaw")
		
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
	$Timer_Label.play = !$Timer_Label.play
	if !$Timer_Label.play:
		disable_attack_buttons(true)
		disable_defend_buttons(true)
	else:
		disable_attack_buttons(false)

func _on_attack_submit_pressed():
	$Timer_Label.play = false
	$Timer_Label2.play = true
	disable_attack_buttons(true)
	disable_defend_buttons(false)
	$DefenseSubmit.disabled = false

func _on_defense_submit_pressed():
	$Timer_Label2.play = false
	disable_defend_buttons(true)
	$Window/OptionButton.select(-1)
	$Window/SpinBox.value = 0
	$Window.visible = true

func _on_button_pressed():
	$Window.visible = false
	disable_attack_buttons(false)
	$Timer_Label.play = true
