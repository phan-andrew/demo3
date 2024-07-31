extends Node
var starting_music = false
var scrolling_music = false
var playing_music = false

func _ready():
	$theme.play()
func start_music():
	if !$start_music.playing:
		$play_music.playing = false
		$start_music.playing = true
		$scroll_music.playing = false
		
func scroll_music(speed):
	if speed == 0:
		$scroll_music.stream_paused = true
	else:	
		$scroll_music.stream_paused = false
		$scroll_music.pitch_scale = speed
	if !$scroll_music.playing && !$scroll_music.stream_paused:
		$start_music.playing = false
		$scroll_music.playing = true
			
func play_music():
	if !$play_music.playing:
		$scroll_music.playing = false
		$play_music.playing = true

func mouse_click():
	$mouse_click.playing = true
	
func _process(delta):
	pass

func change_theme():
	if Settings.theme == 0:
		$theme.stream = preload("res://audio/themes/sea.mp3")
		$theme.volume_db = 0
	if Settings.theme == 1:
		$theme.stream = preload("res://audio/themes/air.mp3")
		$theme.volume_db = 0
	if Settings.theme == 2:
		$theme.stream = preload("res://audio/themes/land.mp3")
		$theme.volume_db = 0
	$theme.play()
		
