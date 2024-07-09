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



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $dropdown.generateACard && numA < 3:		
		aCards[numA].setCard("a", $dropdown.attack_choice)
		aCards[numA].play()
		$dropdown.generateACard = false
		numA += 1
		
	if $dropdown.generateDCard && numD < 3:		
		dCards[numD].visible = true
		$dropdown.generateDCard = false
		numD += 1
		
