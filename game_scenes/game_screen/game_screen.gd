extends Node2D

var aCards
var dCards
var buttons
var aPics
var numA = 0
var numD = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	aCards = [$a_1, $a_2, $a_3]
	dCards = [$d_1, $d_2, $d_3]
	buttons = [$ProgressBar/submit_button, $dropdown/attack_option, $dropdown/defend_option]
	$a_1.cardType = "a"
	$a_2.cardType = "a"
	$a_3.cardType = "a"
	$d_1.cardType = "d"
	$d_2.cardType = "d"
	$d_3.cardType = "d"



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
					card.setCost(0)
					card.play()
					$dropdown.generateACard = false
	if $dropdown.generateDCard && numD < 3:		
		dCards[numD].visible = true
		$dropdown.generateDCard = false
		numD += 1
		
func disable_buttons(state):
	for button in buttons:
		button.disabled = state
	for card in aCards:
		card.disable_buttons(state)
	
	

func _on_debate_pressed():
	$Timer_Label.play = !$Timer_Label.play
	if !$Timer_Label.play:
		disable_buttons(true)
	else:
		disable_buttons(false)
