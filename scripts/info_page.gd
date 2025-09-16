extends Panel

@onready var info_page: Panel = $"."
@onready var close_button: TextureRect = $close_prompt/close_button
@onready var close_message: Label = $close_prompt/close_message
@onready var info_timer: Timer = $info_timer

var can_close = false

func _ready() -> void:
	close_button.visible = false

func _process(_delta: float) -> void:
	if not can_close:
		close_message.text = str(round(int(info_timer.time_left)) + 1)

func _input(_event: InputEvent) -> void:
	if can_close:
		if Input.is_action_just_pressed("click"):
			info_page.visible = false
			can_close = false
			await get_tree().create_timer(0.5).timeout
			Global.info_panel_open = false			

func _on_info_timer_timeout() -> void:
	can_close = true
	close_message.text = "Close"
	close_button.visible = true

func _on_launch_game_delay_timeout() -> void:
	Global.can_launch_game = true
