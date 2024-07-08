extends Node2D

var flipped = false
var hovering = false
var reset_count = 0
var reset = 50
var inPlay = false
var aPics = ["res://cards/attack/Account Manipulation.png","res://cards/attack/BITS Jobs.png","res://cards/attack/Implant Internal Image.png"]
var dPics = []
var aBack = "res://cards/redcard-back.png"
var bBack = "res://cards/bluecard-back.png" 
var cardType

# Called when the node enters the scene tree for the first time.
func _ready():
	$card.z_index = -1
	$card/card_back.z_index = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if inPlay:
		if hovering:
			reset_count = 0
			if !flipped:
				if cardType == "a":
					$card/card_back.frame = 1
				if cardType == "d":
					$card/card_back.frame = 2
				$AnimationPlayer.play("card_flip")
				flipped = true
				
		else: 
			reset_count +=1 
		if reset_count > reset && flipped:
			$AnimationPlayer.play_backwards("card_flip")
			flipped = false
			
func setCard(type, index):
	cardType = type
	if type == "a":		
		$card.texture = load(aPics[index])
	if type == "d":
		$card.texture = load(dPics[index])




func _on_area_2d_mouse_shape_entered(shape_idx):
	hovering = true	

func _on_area_2d_mouse_shape_exited(shape_idx):
	hovering = false
	
func play():
	$AnimationPlayer.play("start_flip")
	inPlay = true
