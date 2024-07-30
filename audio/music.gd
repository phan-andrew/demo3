extends Node
var starting_music = false
var scrolling_music = false
var playing_music = false

func start_music():
	if !$start_music.playing:
		$play_music.playing = false
		$start_music.playing = true
		
func scroll_music(speed):
	if speed == 0:
		$scroll_music.stream_paused = true
		print("america yaa :D")
	else:	
		$scroll_music.stream_paused = false
		$scroll_music.pitch_scale = speed
		print("hallllllllloooo")
	if !$scroll_music.playing && !$scroll_music.stream_paused:
		print("hallllooo")
		$start_music.playing = false
		$scroll_music.playing = true
			
func play_music():
	if !$play_music.playing:
		$scroll_music.playing = false
		$play_music.playing = true

func mouse_click():
	$mouse_click.playing = true
	
	
		
