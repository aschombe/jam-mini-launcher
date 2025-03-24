extends Control
class_name Previewer

#handles all of the game preview logic

@export var Title : TextureRect

@export var previewStreamPlayer : VideoStreamPlayer
@export var bgStreamPlayer : CanvasItem

var next_video : VideoStream

var fading_in = false
var fading_out = false
var timer_fade_in = 0
var timer_fade_out = 99
var fade_in_duration = 0.25
var fade_out_duration = 0.5

func _ready() -> void:
	Title.global_position.x = get_viewport_rect().size.x / 2 - Title.size.x/2

func setGamePreview(titleImage : Texture2D, videoFile : VideoStream):
	next_video = videoFile
	fadeOutVideo()

func fadeInVideo():
	fading_in = true
	timer_fade_in = 0

func fadeOutVideo():
	timer_fade_out = min(timer_fade_out,fade_out_duration) # if the fade_out is interrupted, continue with the most recent value
	fading_out = true

func switch_videos():
	previewStreamPlayer.stream = next_video
	previewStreamPlayer.play()
	fadeInVideo()

func _process(delta: float) -> void:
	#fading in functionality
	if(fading_in):
		timer_fade_in += delta
		if(timer_fade_in > fade_in_duration):
			fading_in = false
			timer_fade_in = fade_in_duration
		previewStreamPlayer.modulate.a = timer_fade_in/fade_in_duration
	
	#fading out
	if(fading_out):
		timer_fade_out -= delta
		if(timer_fade_out < 0):
			fading_out = false
			timer_fade_out = 0
		previewStreamPlayer.modulate.a = timer_fade_out/fade_out_duration
		if(fading_out == false): # helps the functionality for interrupting the fade-out
			timer_fade_out = fade_out_duration
			switch_videos()
