extends Node2D

var flipped = false
var hovering = false
var reset_count = 0
var reset = 50
var inPlay = false
var dPics = []
var aBack = "res://images/card_images/general/redcard-back.png"
var bBack = "res://images/card_images/general/bluecard-back.png" 
var cost=["res://images/card_images/general/1 Dollar.png", "res://images/card_images/general/2 Dollars.png", "res://images/card_images/general/3 Dollars.png"]
var cardType
var original_pos_x
var original_pos_y
var expand_pos_x
var expand_pos_y 
var expanded = false
var reset_dropdown = false
var card_index = -1

  
# Called when the node enters the scene tree for the first time.
func _ready():
	$card.z_index = -1
	$card/card_back.z_index = 0
	original_pos_y = position.y
	original_pos_x  = position.x



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if inPlay:
		if !expanded:
			$close_button.show()
			$expand_button.show()
			
		if hovering:
			reset_count = 0
			if !flipped:
				if cardType == "a":
					$card/card_back.frame = 1
				if cardType == "d":
					$card/card_back.frame = 2
				$AnimationPlayer.play("card_flip")
				print($AnimationPlayer.current_animation_position)
				#while $AnimationPlayer.current_animation_position < 0.2:
					#print("hehehaw")
				flipped = true
				
		else: 
			reset_count +=1 
		if reset_count > reset && flipped:
			$AnimationPlayer.play_backwards("card_flip")
			flipped = false
		
	
			
func setCard(index):
	if cardType == "a":		
		$card.texture = load(Mitre.attack_dict[index][4])
	if cardType == "d":
		$card.texture = load(dPics[index])
	card_index = index



func _on_area_2d_mouse_shape_entered(shape_idx):
	hovering = true	

func _on_area_2d_mouse_shape_exited(shape_idx):
	hovering = false
	
func play():
	$AnimationPlayer.play("start_flip")
	inPlay = true

func _on_expand_button_pressed():
	print(original_pos_x)
	print(original_pos_y)
	if !expanded:
		if cardType == "a":					
			expand_pos_x = 300
			expand_pos_y = 300
		if cardType == "d":					
			expand_pos_x = 850
			expand_pos_y = 300
		position.x = expand_pos_x
		position.y = expand_pos_y
		scale.x *= 2
		scale.y *= 2
		z_index = 5
		$expand_button.icon = load("res://images/UI_images/shrink_button.png")
		$expand_button.position.x -= 150
		expanded = true
		$close_button.hide()
		
	else:
		scale.x /= 2
		scale.y /= 2
		position.x = original_pos_x
		position.y = original_pos_y
		z_index = 1
		$expand_button.icon = load("res://images/UI_images/expand_button.png")
		$expand_button.position.x += 150
		expanded = false
		$close_button.show()
		print("skibisidi")


func _on_close_button_pressed():
	reset_card()
	reset_dropdown = true

func reset_card():
	inPlay = false
	$close_button.hide()
	$expand_button.hide()
	$card/card_back.frame = 0
	$AnimationPlayer.play("end_flip")
	card_index = -1
	
	
func disable_buttons(state):
	$close_button.disabled = state
	#$expand_button.disabled = state

func setText(index):
	if cardType=="a":
		$card/definition.text=(Mitre.attack_dict[index][3])
		$card/definition.hide()
		
func setCost(Cost):
	if cardType=="a":
		$card/Dollar.texture=load(cost[Cost])
		$card/Dollar.z_index = 2
		$card/Dollar.hide()
		print("erm what the sgima")
func setTimeImage():
	if cardType=="a":
		$card/Clock.texture=load("res://images/card_images/general/Clock.png")
		$card/Clock.hide()
func setTimeValue(value):
	if cardType=="a":
		$card/Time.text=value
