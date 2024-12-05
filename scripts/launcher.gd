extends Control

const JSON_DIR : String = "/home/andrew/Documents/projects/jam-mini-launcher/jsons/"
const GAME_DIR : String = "/home/andrew/Documents/projects/jam-mini-launcher/games/"

@onready var game_grid: GridContainer = $game_scroller/game_grid

var jsons : DirAccess 
var json_name : String
var game_jsons : PackedStringArray
var games : DirAccess
var folder_name : String

var game_folder : String
var game_exec_path : String
var game_thumbnail_path : String
var thumbnail_texture : Texture2D
var resized_thumbnail : Image
var game_folder_contents : PackedStringArray

var game_button : Button

var json_string : String 
var json_dict : Dictionary
@onready var info_panel: Control = $info_panel
@onready var game_title: Label = $info_panel/game_title
@onready var author: Label = $info_panel/author
@onready var genres: Label = $info_panel/genres
@onready var description: Label = $info_panel/description
@onready var play_button: Button = $info_panel/play_button

var info_name
var info_genres
var info_author
var info_description

var game_running : bool = false
var running_pid : int = -1
var connected = false

@onready var selected_game: ColorRect = $selected_game

func _process(_delta: float) -> void:
	# Prevents more than one game from being launched at a time
	if game_running and OS.is_process_running(running_pid) == false:
		game_running = false

func _ready() -> void:
	info_panel.visible = false
	selected_game.visible = false
	
	# Find all the names of the json files
	jsons = DirAccess.open(JSON_DIR)
	if jsons:
		jsons.list_dir_begin()
		json_name = jsons.get_next()
		while json_name != "":
			json_name = json_name.get_basename()
			game_jsons.append(json_name)
			json_name = jsons.get_next()
	game_jsons.sort()
			
	# Collect and sort all the game folder names
	var folder_names = []
	games = DirAccess.open(GAME_DIR)
	if games:
		games.list_dir_begin()
		folder_name = games.get_next()
		while folder_name != "":
			# Skip non-folder entries and "." / ".."
			if not games.current_is_dir() or folder_name.begins_with("."):
				folder_name = games.get_next()
				continue
			folder_names.append(folder_name)
			folder_name = games.get_next()
		folder_names.sort()  # Sort folder names alphabetically

	# Check every folder in the sorted list
	for folder_name in folder_names:
		if game_jsons.has(folder_name):
			# Create the file paths
			game_folder = GAME_DIR + folder_name
			game_folder_contents = DirAccess.get_files_at(game_folder)
			game_thumbnail_path = game_folder + "/" + folder_name + ".png"
			game_exec_path = game_folder + "/" + folder_name + ".x86_64"

			# Instantiate and add the button
			game_button = Button.new()

			# Style the button
			game_button.set_flat(true)
			var style_box = StyleBoxFlat.new()
			game_button.add_theme_stylebox_override("normal", style_box)
			game_button.add_theme_stylebox_override("hover", style_box)
			game_button.add_theme_stylebox_override("pressed", style_box)
			game_button.add_theme_stylebox_override("focused", style_box)

			game_button.set_meta("exec_path", game_exec_path)  # Store the exec path

			# Open the corresponding JSON and attach all the relevant information to the button as metadata
			var json_file = FileAccess.open(JSON_DIR + folder_name + ".json", FileAccess.READ)
			if json_file:
				json_string = json_file.get_as_text()  # Read the entire JSON file as a single string
				var json = JSON.new()
				var parse_result = json.parse(json_string)
				if parse_result != OK:
					print("JSON Parse Error: ", json.get_error_message(), " in ", json_string)
				else:
					var data = json.get_data()
					if data.has("name"):
						info_name = data["name"]
					if data.has("author"):
						info_author = data["author"]
					if data.has("description"):
						info_description = data["description"]
					if data.has("genres"):
						info_genres = data["genres"]

					# Attach metadata to the button
					game_button.set_meta("name", info_name)
					game_button.set_meta("author", info_author)
					game_button.set_meta("description", info_description)
					game_button.set_meta("genres", info_genres)
			else:
				print("Failed to open JSON file: ", folder_name + ".json")

			add_child(game_button)
			thumbnail_texture = load(game_thumbnail_path)
			resized_thumbnail = thumbnail_texture.get_image()
			resized_thumbnail.resize(235, 187)
			game_button.icon = ImageTexture.create_from_image(resized_thumbnail)
			game_button.reparent(game_grid)

			# Connect the button signal, and bind the game_button as an input to it
			game_button.connect("pressed", update_info_panel.bind(game_button))
			game_button.connect("mouse_entered", focus_button.bind(game_button))
			game_button.connect("mouse_exited", unfocus_button.bind(game_button))

func focus_button(button: Button) -> void:
	selected_game.visible = true
	selected_game.global_position = button.global_position

func unfocus_button(button: Button) -> void:
	selected_game.visible = false

func update_info_panel(button: Button) -> void:
	# Populate the labels with the appropriate text
	game_title.text = button.get_meta("name")
	author.text = button.get_meta("author")
	description.text = button.get_meta("description")
	genres.text = button.get_meta("genres")	

	# Connect the button signal, and bind the game_button as an input to it
	if connected:
		play_button.disconnect("pressed", _on_game_button_pressed)
		connected = false
	play_button.connect("pressed", _on_game_button_pressed.bind(button))
	connected = true
	info_panel.visible = true

# Callback for when a button is pressed
func _on_game_button_pressed(button: Button) -> void:
	if game_running:
		return
		
	var exec_path = button.get_meta("exec_path")  # Retrieve the exec path from metadata
	if exec_path:
		running_pid = OS.create_process(exec_path, [])
		game_running = true
	else:
		print("No exec path found for button: ", button.name)
