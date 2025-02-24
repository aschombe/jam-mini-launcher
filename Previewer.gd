extends Control
class_name Previewer

#handles all of the game preview logic

@export var Title : TextureRect

@export var previewStreamPlayer : VideoStreamPlayer
@export var bgStreamPlayer : VideoStreamPlayer

var fading_in = false
var timer_fade_in = 0
var fade_in_duration = 0.5

func _ready() -> void:
	Title.global_position.x = get_viewport_rect().size.x / 2 - Title.size.x/2

func setGamePreview(titleImage, videoFile):
	pass

func FadeInVideo():
	timer_fade_in = 0
	fading_in = 0

func _process(delta: float) -> void:
	if(fading_in):
		timer_fade_in += delta
		previewStreamPlayer.modulate.a = timer_fade_in/fade_in_duration
