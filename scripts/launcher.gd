extends Control

const JSON_DIR: String = "/home/andrew/Documents/projects/jam-mini-launcher/jsons/"
const GAME_DIR: String = "/home/andrew/Documents/projects/jam-mini-launcher/games/"

@onready var game_grid: GridContainer = $game_scroller/game_grid
@onready var info_panel: Control = $info_panel
@onready var game_title: Label = $info_panel/game_title
@onready var author: Label = $info_panel/author
@onready var genres: Label = $info_panel/genres
@onready var description: Label = $info_panel/description
@onready var play_button: Button = $info_panel/play_button
@onready var play_focus: ColorRect = $info_panel/play_button/play_focus
@onready var selected_game: ColorRect = $selected_game

var jsons: DirAccess
var game_jsons: PackedStringArray
var folder_names: Array = []
var buttons: Array = []  # 2D array to hold buttons
var panel_updated : bool = false
var game_running: bool = false
var running_pid: int = -1
var connected  : bool = false
var last_button_pressed : Button
var start_button_focused : bool = false

func _process(_delta: float) -> void:
	# Prevents more than one game from being launched at a time
	if game_running and not OS.is_process_running(running_pid):
		game_running = false
		
	# Prevents inputs while game is running
	if not game_running:
		set_process_input(true)

func _ready() -> void:
	# Initialize variables
	info_panel.visible = false
	selected_game.visible = false
	play_focus.visible = false
	buttons.clear()

	# Collect and sort JSON file names
	_load_json_files()

	# Collect and sort folder names
	_load_game_folders()

	# Create buttons for game folders
	_create_game_buttons()

	# Set the neighbors for each button
	set_neighbors(buttons)
	
	# Focus the first button
	if buttons.size() > 0:
		game_grid.get_child(0).grab_focus()

# Function to load JSON files
func _load_json_files() -> void:
	jsons = DirAccess.open(JSON_DIR)
	if jsons:
		jsons.list_dir_begin()
		var json_name: String = jsons.get_next()
		while json_name != "":
			if json_name.ends_with(".json"):
				game_jsons.append(json_name.get_basename())
			json_name = jsons.get_next()
	game_jsons.sort()

# Function to load game folder names
func _load_game_folders() -> void:
	var folder_name: String
	var games : DirAccess = DirAccess.open(GAME_DIR)
	if games:
		games.list_dir_begin()
		folder_name = games.get_next()
		while folder_name != "":
			if games.current_is_dir() and not folder_name.begins_with("."):
				folder_names.append(folder_name)
			folder_name = games.get_next()
	folder_names.sort()

# Function to create buttons for each game
func _create_game_buttons() -> void:
	var row : Array = []
	for folder_name in folder_names:
		if game_jsons.has(folder_name):
			var game_button : Button = _create_game_button(folder_name)
			game_grid.add_child(game_button)
			row.append(game_button)

			# Add to buttons array when row is complete
			if row.size() == 2:
				buttons.append(row)
				row = []

	# Add any remaining buttons if the row isn't complete
	if row.size() > 0:
		buttons.append(row)

# Create a game button with all its properties
func _create_game_button(folder_name: String) -> Button:
	var game_folder : String = GAME_DIR + folder_name
	var game_exec_path : String = game_folder + "/" + folder_name + ".x86_64"
	var game_thumbnail_path : String = game_folder + "/" + folder_name + ".png"
	var json_data : Dictionary = _load_game_json(folder_name)

	var game_button : Button = Button.new()
	game_button.set_flat(true)
	var style_box : StyleBoxFlat = StyleBoxFlat.new()
	game_button.add_theme_stylebox_override("normal", style_box)
	game_button.add_theme_stylebox_override("hover", style_box)
	game_button.add_theme_stylebox_override("pressed", style_box)
	game_button.add_theme_stylebox_override("focused", style_box)
	game_button.set_meta("exec_path", game_exec_path)
	game_button.set_meta("name", json_data.name)
	game_button.set_meta("author", json_data.author)
	game_button.set_meta("description", json_data.description)
	game_button.set_meta("genres", json_data.genres)

	# Add thumbnail to the button
	var thumbnail_texture : Resource = load(game_thumbnail_path)
	var resized_thumbnail : Image = thumbnail_texture.get_image()
	resized_thumbnail.resize(235, 187)
	game_button.icon = ImageTexture.create_from_image(resized_thumbnail)

	# Connect signals for interaction
	game_button.connect("pressed", focus_start.bind(game_button))
	game_button.connect("focus_entered", update_info_panel.bind(game_button))
	game_button.connect("focus_entered", focus_button.bind(game_button))

	return game_button

func focus_start(button: Button):
	last_button_pressed = button
	start_button_focused = true
	play_button.grab_focus()


func _input(_event: InputEvent) -> void:
	if Input.is_action_pressed("ui_cancel") and start_button_focused:
		last_button_pressed.grab_focus()
		start_button_focused = false

# Load game JSON data
func _load_game_json(folder_name: String) -> Dictionary:
	var json_string: String
	var json_dict: Dictionary = {}
	var json_file = FileAccess.open(JSON_DIR + folder_name + ".json", FileAccess.READ)
	if json_file:
		json_string = json_file.get_as_text()
		var json : JSON = JSON.new()
		if json.parse(json_string) == OK:
			json_dict = json.get_data()
	return json_dict

# Set the neighbors for each button in the grid
func set_neighbors(button_arr: Array) -> void:
	for row_index in range(button_arr.size()):
		var row : Array = button_arr[row_index]
		for col_index in range(row.size()):
			var button : Button = row[col_index]
			_set_button_neighbors(button, row, col_index, row_index)

# Set neighbors for a single button
func _set_button_neighbors(button: Button, row: Array, col_index: int, row_index: int) -> void:
	# Set the neighbors for the button (left, right, top, bottom)
	if col_index > 0:
		button.focus_neighbor_left = row[col_index - 1].get_path()
	if col_index < row.size() - 1:
		button.focus_neighbor_right = row[col_index + 1].get_path()
	# If the button is a right column button, set its right neighbor to itself
	if col_index == row.size() - 1:
		button.focus_neighbor_right = button.get_path()
	if row_index > 0 and col_index < buttons[row_index - 1].size():
		button.focus_neighbor_top = buttons[row_index - 1][col_index].get_path()
	if row_index < buttons.size() - 1 and col_index < buttons[row_index + 1].size():
		button.focus_neighbor_bottom = buttons[row_index + 1][col_index].get_path()
	# If the button is in the last row, set its bottom neighbor to itself
	if row_index == buttons.size() - 1:
		button.focus_neighbor_bottom = button.get_path()


# Highlight the selected game on hover
func focus_button(button: Button) -> void:
	selected_game.visible = true
	selected_game.global_position = button.global_position

# Update the info panel with game details
func update_info_panel(button: Button) -> void:
	panel_updated = true
	game_title.text = button.get_meta("name")
	author.text = button.get_meta("author")
	description.text = button.get_meta("description")
	genres.text = button.get_meta("genres")
	if connected:
		play_button.disconnect("pressed", _on_play_button_pressed)
		connected = false
	play_button.connect("pressed", _on_play_button_pressed.bind(button))
	connected = true
	info_panel.visible = true

# Callback for when a button is pressed
func _on_game_button_pressed(button: Button) -> void:
	update_info_panel(button)

# Launch the selected game
func _on_play_button_pressed(button: Button) -> void:
	if game_running:
		return
	var exec_path : String = button.get_meta("exec_path")
	if exec_path:
		running_pid = OS.create_process(exec_path, ["-f"])
		game_running = true
		# PAUSE INPUT HERE
		set_process_input(false)
	else:
		print("No exec path found for button: ", button.name)

func _on_play_button_focus_entered() -> void:
	if panel_updated:
		selected_game.visible = false
		play_focus.visible = true

func _on_play_button_focus_exited() -> void:
	selected_game.visible = true
	play_focus.visible = false
