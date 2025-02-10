extends Control
class_name MenuScroll

@export var icon_prefab : PackedScene

@export var topRowContainer : Node2D
@export var fps_text : Label

@export var texArr : Array[Texture2D]
@export var screenCenter : float = 500

var icon_refs : Array[TextureRect] = []

var cursorPos : Vector2 = Vector2.ZERO
var speed = 0.5;

func _draw():
	pass#draw_rect(Rect2(Vector2.ZERO, Vector2.ONE * 20),Color.AQUA,true,2,true);

func _ready() -> void:
	screenCenter = get_viewport_rect().get_center().x - 50
	initialize.call_deferred(texArr)

#instantiates all the icons and sets them up for viewing
func initialize(arr:Array[Texture2D]) -> void:
	if(arr):
		texArr = arr
	for i in range(0,texArr.size()):
		var icon_instance = icon_prefab.instantiate()
		icon_instance.texture = texArr[i]
		icon_instance.material = icon_instance.material.duplicate()
		icon_instance.global_position.x += icon_instance.size.x * i
		topRowContainer.add_child(icon_instance);
		icon_refs.push_back(icon_instance)

func _process(delta: float) -> void:
	#moving the icons
	if(Input.is_action_just_pressed('right')):
		move_cursor(Vector2(1,0));
	if(Input.is_action_just_pressed('left')):
		move_cursor(Vector2(-1,0));
	
	fps_text.text = str(Engine.get_frames_per_second()) + '\n' + str(cursorPos)
	
	update_icon_positions();

func move_cursor(menu_vec:Vector2):
	cursorPos += menu_vec
	if(cursorPos.x < 0):
		cursorPos.x = icon_refs.size()-1
		update_icon_positions(false);
	if(cursorPos.x > icon_refs.size()-1):
		cursorPos.x = 0
		update_icon_positions(false);


func update_icon_positions(smooth=true):
	for i in range(0,icon_refs.size()):
		var icon = icon_refs[i];
		if(smooth):
			icon.global_position.x = lerpf(icon.global_position.x,icon.size.x * i + (cursorPos.x - icon_refs.size()) * icon.size.x + screenCenter,speed)
		else:
			icon.global_position.x = icon.size.x * i + (cursorPos.x - icon_refs.size()) * icon.size.x + screenCenter;
		
		if icon.material != null:
			icon.material.set_shader_parameter("xpos",-(screenCenter - icon.global_position.x)/120);

func set_cursor(menu_pos:Vector2):
	cursorPos = menu_pos
