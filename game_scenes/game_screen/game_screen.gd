extends Node2D

var aCards
var dCards
var aPics
var numA = 0
var numD = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	aCards = [$a_1, $a_2, $a_3]
	dCards = [$d_1, $d_2, $d_3]
	$a_1.cardType = "a"
	$a_2.cardType = "a"
	$a_3.cardType = "a"
	$d_1.cardType = "d"
	$d_2.cardType = "d"
	$d_3.cardType = "d"
	print("yay")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $dropdown.generateACard:		
		for card in aCards:
			if $dropdown.generateACard:
				if !card.inPlay:				
					card.setCard($dropdown.attack_choice)
					card.play()
					$dropdown.generateACard = false
				
			
	if $dropdown.generateDCard && numD < 3:		
		dCards[numD].visible = true
		$dropdown.generateDCard = false
		numD += 1
		
