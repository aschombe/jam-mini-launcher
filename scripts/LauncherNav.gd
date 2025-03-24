extends Control
class_name Launcher

@export var GAME_DIR: String = "C:/Users/filip/Downloads/Games/Games/"

@export var menu : MenuScroll
@export var preview : Previewer

@export var TitleLabel : RichTextLabel

var games : Array[Game] = []

var cooldown: bool = false

var current_game : int = 0

#animation variables
var title_t = 0
var title_dur = 0.2


# LOAD FUNCTIONS ---------------------------------------------------------------------------------
# midfied Andrew's launcher code

#load the game folders into an array
func _load_game_folders() -> Array[String]:
	var folder_names : Array[String] = []
	var folder_name : String
	var games : DirAccess = DirAccess.open(GAME_DIR)
	if games :
		games.list_dir_begin()
		folder_name = games.get_next()
		while folder_name != "":
			if games.current_is_dir() and not folder_name.begins_with("."):
				var json_path: String = GAME_DIR + folder_name + "/" + folder_name + ".json"
				if FileAccess.file_exists(json_path):
					folder_names.append(folder_name)
			folder_name = games.get_next()
	folder_names.sort()
	return folder_names

# load game info and resources
func _load_game_info(folder) -> void:
	var game = _load_game_json(folder)
		
	game.video = load(GAME_DIR + folder + "/" + folder + ".ogv")
		
	var image : Image = Image.load_from_file(GAME_DIR + folder + "/" + folder + ".png")
	image.resize(235, 187)
	game.texture = ImageTexture.create_from_image(image)
		
	game.exec_path = (GAME_DIR + folder + "/" + folder[0].to_upper() + folder.substr(1, -1) + ".app")
		
	games.append(game)

func load_all_games(folder_names) -> void:
	for folder in folder_names:
		_load_game_info(folder)

func _load_game_json(folder_name: String) -> Game:
	#get folder
	var json_path: String = GAME_DIR + folder_name + "/" + folder_name + ".json"
	
	#init vars
	var json_string: String
	var json_dict: Game = Game.new()
	var json_file = FileAccess.open(json_path, FileAccess.READ)
	if json_file:
		json_string = json_file.get_as_text()
		var json: JSON = JSON.new()
		if json.parse(json_string) == OK:
			json_dict.loadFromJsonDict(json.get_data())
	return json_dict

# DISPLAY FUNCTIONS -------------------------------------------------------------------------------
# run only after games are loaded in
func DisplayIcons():
	var texarr : Array[Texture2D] = []
	for game in games:
		texarr.push_front(game.texture)
	menu.initialize(texarr)

func on_cursor_update(cursor):
	current_game = cursor
	update_preview_video(games[cursor])
	fade_in_Title(games[cursor].game_title)

func update_preview_video(game:Game):
	preview.setGamePreview(null,game.video)

func fade_in_Title(text:String):
	TitleLabel.text = "[center]" + text + "[/center]"
	TitleLabel.global_position = Vector2(get_viewport_rect().get_center().x - TitleLabel.size.x/2,TitleLabel.global_position.y)
	title_t = title_dur

# OTHER -------------------------------------------------------------------------------------------
# figure out what this does
func _start_cooldown(duration: float) -> void:
	cooldown = true
	await get_tree().create_timer(duration).timeout
	cooldown = false

func _ready():
	#loads in all the games
	load_all_games(_load_game_folders())
	
	#Display all in menu
	menu.on_cursor_changed.connect(on_cursor_update)
	DisplayIcons()
	update_preview_video(games[0])

func _process(delta: float) -> void:
	#handle the title animation
	if(title_t > 0):
		title_t -= delta
	else:
		title_t = 0
