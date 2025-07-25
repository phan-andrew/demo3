extends Label

var scroll_speed: float = 50.0  # Pixels per second
var reset_delay: float = 1.0    # Delay before restart
var scroll_offset: float = 0.0
var scrolling: bool = false
var delay_timer: float = 0.0

func _ready():
	scrolling = true
	scroll_offset = 0.0
	set_clip_text(true) # ensure text is clipped visually

func _process(delta):
	if not scrolling:
		return
	
	var font = self.get_theme_font("font")  # gets the current font used by the Label
	var text_width = font.get_string_size(text).x

	var label_width = size.x

	if text_width > label_width:
		scroll_offset -= scroll_speed * delta
		if scroll_offset < -text_width:
			delay_timer += delta
			if delay_timer > reset_delay:
				scroll_offset = label_width
				delay_timer = 0.0
	else:
		scroll_offset = 0.0  # No scrolling if it fits
	
	self.position.x = scroll_offset
