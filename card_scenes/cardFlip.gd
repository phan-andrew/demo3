extends Node2D

var flipped = false
var inPlay = false
var dPics = []
var aBack = "res://images/card_images/general/redcard-back.png"
var dBack = "res://images/card_images/general/bluecard-back.png"
var cost=["res://images/card_images/general/1 Dollar.png", "res://images/card_images/general/2 Dollars.png", "res://images/card_images/general/3 Dollars.png", "res://images/card_images/general/4 Dollars.png", "res://images/card_images/general/5 Dollars.png", "res://images/card_images/general/6 Dollar.png", "res://images/card_images/general/7 Dollars.png", "res://images/card_images/general/8 Dollars.png", "res://images/card_images/general/9 Dollars.png", "res://images/card_images/general/10 Dollars.png"]
var maturity=["res://images/card_images/general/1 Star.png", "res://images/card_images/general/2 Stars.png", "res://images/card_images/general/3 Stars.png", "res://images/card_images/general/4 Stars.png", "res://images/card_images/general/5 Stars.png"]
var cardType
var original_pos_x
var original_pos_y
var expand_pos_x
var expand_pos_y
var expanded = false
var reset_dropdown = false
var card_index = -1
var time_value = 0
var cost_value = 1
var maturity_level = 1

# FIXED: Add tracking variables for slider changes
var previous_cost_value = 1
var previous_time_value = 0
var previous_maturity_value = 1
var sliders_interactive = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$card.z_index = -1
	$card/card_back.z_index = 0
	original_pos_y = position.y
	original_pos_x  = position.x
	disable_buttons(true)
	$card/sliders.hide()
	$card/Clock.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if inPlay:
		# FIXED: Only update values when sliders are actually interactive and values have changed
		if sliders_interactive:
			if cardType == "a":
				# Check if cost slider value has changed
				var current_cost = $card/sliders/cost_slider.value
				if current_cost != previous_cost_value:
					cost_value = current_cost
					$card/Dollar.texture = load(cost[cost_value-1])
					previous_cost_value = current_cost
					print("Cost manually changed to: ", cost_value)
				
				# Check if time slider value has changed
				var current_time = $card/sliders/time_slider.value
				if current_time != previous_time_value:
					time_value = current_time
					$card/Time.text = str(time_value) 
					previous_time_value = current_time
					print("Time manually changed to: ", time_value)
					
					# Update clock display based on time
					if time_value > 90:
						$card/Clock.play("full")
					elif time_value > 60:
						$card/Clock.play("0.75")
					elif time_value > 30:
						$card/Clock.play("0.25")
					else:
						$card/Clock.play("none")
			
			if cardType == "d":
				$card/Clock.play("nothing")
				# Check if maturity slider value has changed
				var current_maturity = $card/sliders/maturity_slider.value
				if current_maturity != previous_maturity_value:
					maturity_level = current_maturity
					$card/Maturity.texture = load(maturity[maturity_level-1])
					previous_maturity_value = current_maturity
					print("Maturity manually changed to: ", maturity_level)
	
func setCard(index):
	card_index = int(index)

	if cardType == "a":
		var attack = Mitre.attack_dict[index + 1]
		$card.texture = load(attack[4])
		$card/sliders/maturity_slider.hide()

		var cost = 1
		if attack.size() > 5:
			cost = int(attack[5])

		var time = 1
		if attack.size() > 6:
			time = int(attack[6])

		setCost(cost)
		setTimeValue(time)

	if cardType == "d":
		var defend = Mitre.defend_dict[int(index) ]
		$card.texture = load(defend[5])
		$card/sliders/cost_slider.hide()
		$card/sliders/time_slider.hide()
		$card/Clock.hide()

		var maturity = 2
		if defend.size() > 6:
			maturity = int(defend[6])

		setMaturity(maturity)

func play():
	$AnimationPlayer.play("start_flip")
	inPlay = true
	
	# FIXED: Enable slider interactivity when card is played
	sliders_interactive = true
	if cardType == "a":
		$card/sliders.show()
		$card/sliders/cost_slider.show()
		$card/sliders/time_slider.show()
		$card/sliders/maturity_slider.hide()
		$card/Clock.show()
	elif cardType == "d":
		$card/sliders.show()
		$card/sliders/cost_slider.hide()
		$card/sliders/time_slider.hide()
		$card/sliders/maturity_slider.show()
		$card/Clock.hide()
	
	if has_node("/root/Music"):
		var music = get_node("/root/Music")
		if music.has_method("flip_card"):
			music.flip_card()
	disable_buttons(false)

func _on_expand_button_pressed():
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
		$expand_button.position.x -= 50
		$flip_button.position.x -= 150
		expanded = true
		$close_button.hide()
	else:
		scale.x /= 2
		scale.y /= 2
		position.x = original_pos_x
		position.y = original_pos_y
		z_index = 1
		$expand_button.icon = load("res://images/UI_images/expand_button.png")
		$expand_button.position.x += 50
		$flip_button.position.x += 150
		expanded = false
		$close_button.show()

func make_small_again():
	scale.x /= 2
	scale.y /= 2
	position.x = original_pos_x
	position.y = original_pos_y
	z_index = 1
	$expand_button.icon = load("res://images/UI_images/expand_button.png")
	$expand_button.position.x += 50
	$flip_button.position.x += 150
	expanded = false
	$close_button.show()

func _on_close_button_pressed():
	reset_card()
	reset_dropdown = true

func reset_card():
	inPlay = false
	sliders_interactive = false  # FIXED: Disable slider interactivity when card is reset
	disable_buttons(true)
	if cardType == "a":
		$card/card_back.frame = 4
	if cardType == "d":
		$card/card_back.frame = 3
	$AnimationPlayer.play("end_flip")
	
	# FIXED: Reset all values and tracking variables
	time_value = 0
	cost_value = 1
	maturity_level = 1
	previous_cost_value = 1
	previous_time_value = 0
	previous_maturity_value = 1
	
	card_index = -1
	$card/sliders.hide()
	$card/Clock.hide()
	
	if has_node("/root/Music"):
		var music = get_node("/root/Music")
		if music.has_method("flip_card"):
			music.flip_card()

func disable_buttons(state):
	$close_button.disabled = state
	$expand_button.disabled = state
	$flip_button.disabled = state
	
func disable_expand(state):
	$expand_button.disabled = state

func disable_close(state):
	$close_button.disabled = state

func disable_flip(state):
	$flip_button.disabled = state
	
func setText(index):
	if cardType=="a":
		# Attack cards: index 3 = Description
		$card/definition.text=(Mitre.attack_dict[index+1][3])
		$card/definition.hide()
	if cardType=="d":
		# Defense cards: index 4 = Description (index 3 = Name)
		$card/definition.text=(Mitre.defend_dict[int(index)][4])
		$card/definition.hide()

func setCost(Cost):
	if cardType == "a":
		cost_value = Cost
		previous_cost_value = Cost  # FIXED: Update tracking variable
		$card/sliders/cost_slider.value = Cost
		$card/Dollar.texture = load(cost[Cost - 1])

func setTimeValue(value):
	if cardType == "a":
		time_value = value
		previous_time_value = value  # FIXED: Update tracking variable
		$card/sliders/time_slider.value = value
		$card/Time.text = str(value) + " min"

		if value > 90:
			$card/Clock.play("full")
		elif value > 60:
			$card/Clock.play("0.75")
		elif value > 30:
			$card/Clock.play("0.25")
		else:
			$card/Clock.play("none")

func setMaturity(Maturity):
	if cardType == "d":
		maturity_level = Maturity
		previous_maturity_value = Maturity  # FIXED: Update tracking variable
		$card/sliders/maturity_slider.value = Maturity
		$card/Maturity.texture = load(maturity[Maturity - 1])

func getTimeValue():
	return time_value

func getCostValue():
	return cost_value

func getMaturityValue():
	return maturity_level

func getString():
	if cardType == "a":
		# Attack cards: index 2 = Name
		var printable = Mitre.attack_dict[card_index+1][2] + ": $" + str(cost_value) + " " + str(time_value) + " minutes"
		return printable
	if cardType == "d":
		# Defense cards: index 3 = Name (NOT index 2!)
		var printable = Mitre.defend_dict[card_index][3] + ": " + str(maturity_level) + " stars"
		return printable

func _on_flip_button_pressed():
	if flipped:
		$AnimationPlayer.play_backwards("card_flip")
		flipped = false
		if has_node("/root/Music"):
			var music = get_node("/root/Music")
			if music.has_method("flip_card"):
				music.flip_card()
	else :
		if cardType == "a":
			$card/card_back.frame = 1
		if cardType == "d":
			$card/card_back.frame = 2
		$AnimationPlayer.play("card_flip")
		flipped = true
		if has_node("/root/Music"):
			var music = get_node("/root/Music")
			if music.has_method("flip_card"):
				music.flip_card()
