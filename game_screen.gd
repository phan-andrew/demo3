extends Node2D

var aCards
var dCards
var numA = 0
var numD = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	aCards = [$a_1, $a_2, $a_3, $a_4]
	dCards = [$d_1, $d_2, $d_3, $d_4]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $dropdown.generateACard && numA < 4:
		if aCards[numA] != null:
			aCards[numA].visible = true
			$dropdown.generateACard = false
			numA += 1
	if $dropdown.generateDCard && numD < 4:
		if dCards[numD] != null:
			dCards[numD].visible = true
			$dropdown.generateDCard = false
			numD += 1
		
