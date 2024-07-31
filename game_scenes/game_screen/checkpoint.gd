extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$descrip_box.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Settings.theme == 0:
		$weed.show()
		$loon.hide()
		$tree.hide()
	if Settings.theme == 1:
		$weed.hide()
		$loon.show()
		$tree.hide()
	if Settings.theme == 2:
		$weed.hide()
		$loon.hide()
		$tree.show()

func start():
	pass

func _on_area_2d_area_entered(area):
	if area.name == "character":
		$AnimationPlayer.play("RESET")


func _on_area_2d_area_exited(area):
	$AnimationPlayer.play_backwards("RESET")

func set_descrip(descrip):
	$descrip_box/descrip_label.text = descrip
