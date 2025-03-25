extends Control
class_name Launcher

@export_group("Directory")
@export var GAME_DIR: String = "C:/Users/filip/Downloads/Games/Games/"

@export_group("Objects Refs")
@export var menu : MenuScroll
@export var preview : Previewer

@export_group("Label Refs")
@export var TitleLabel : Label
@export var DescObject : Control

@export var AuthLabel : Label
@export var TypeLabel : Label
@export var GenreLabel : Label
@export var DescLabel : Label
@export var YearLabel : Label

var games : Array[Game] = []

var cooldown: bool = false

#runtime variables
var current_game : int = 0
var running_pid = -1
var is_running

#animation variables
var title_t = 0.0
var title_dur = 0.2
var title_start_y = 0.0
var title_offset = 50.0

var desc_t = 0.0
var desc_start_y = 0.0
var desc_offset = 50.0

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
	for i in range(0,folder_names.size()):
		_load_game_info(folder_names[folder_names.size()-1-i])

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

#runs when menu updates
func on_cursor_update(cursor):
	current_game = cursor
	update_preview_video(games[cursor])
	fade_in_Title(games[cursor].game_title)
	fade_in_desc(games[cursor])

#updates the video of the game preview
func update_preview_video(game:Game):
	preview.setGamePreview(null,game.video)

func fade_in_Title(text:String):
	TitleLabel.text = text 
	title_t = title_dur
	
	#resize to fit
	var top_left = TitleLabel.get_character_bounds(0).position
	var temp = TitleLabel.get_character_bounds(TitleLabel.get_total_character_count()-1)
	var bot_right = temp.position + temp.size
	var result_rect = Rect2(top_left,top_left - bot_right)
	TitleLabel.size = result_rect.size
	
	TitleLabel.global_position = Vector2(get_viewport_rect().get_center().x - TitleLabel.size.x/2,TitleLabel.global_position.y)
	animate_title(0)

#sets all the other data besides title
func fade_in_desc(game:Game):
	
	#parse the arrays
	var str = ""
	var genres = ""
	for i in game.author:
		str += i
		if(i != game.author[game.author.size()-1]):
			str += ', '
	for i in game.genres:
		genres += i
		if(i != game.genres[game.genres.size()-1]):
			genres += ', '
	
	#display values
	AuthLabel.text = str
	TypeLabel.text = game.type
	GenreLabel.text = genres
	DescLabel.text = game.description
	YearLabel.text = game.creation_year
	desc_t = title_dur
	animate_desc(0)

#handles the animation itself
func animate_title(delta):
	#clamp to avoid bounce effect
	title_t = clampf(title_t,0,title_dur)
	TitleLabel.global_position.y = lerpf(TitleLabel.global_position.y,(title_t/title_dur) * -title_offset + title_start_y,0.4)
	var c = Color.WHITE
	c.a = 1-(title_t/title_dur) 
	TitleLabel.modulate = c
	if(title_t > 0):
		title_t -= delta

func animate_desc(delta):
	#clamp to avoid bounce effect
	desc_t = clampf(desc_t,0,title_dur)
	DescObject.global_position.y = lerpf(DescObject.global_position.y,(desc_t/title_dur) * desc_offset + desc_start_y,0.4)
	var c = Color.WHITE
	c.a = 1-(desc_t/title_dur) 
	DescObject.modulate = c
	if(desc_offset > 0):
		desc_t -= delta

#running games ------------------------------------------------------------------------------------
func run_current():
	if is_running || cooldown:
		return
	running_pid = games[current_game].exec()
	is_running = true

# OTHER -------------------------------------------------------------------------------------------
# figure out what this does
func _start_cooldown(duration: float) -> void:
	cooldown = true
	await get_tree().create_timer(duration).timeout
	cooldown = false

func _ready():
	var default = games.size() - 1
	#loads in all the games
	load_all_games(_load_game_folders())
	
	#Display all in menu
	menu.on_cursor_changed.connect(on_cursor_update)
	DisplayIcons()
	update_preview_video(games[default])
	title_start_y = TitleLabel.global_position.y
	desc_start_y = DescObject.global_position.y
	fade_in_Title(games[default].game_title)
	fade_in_desc(games[default])

func _process(delta: float) -> void:
	#handle the title animation
	animate_title(delta)
	animate_desc(delta)
