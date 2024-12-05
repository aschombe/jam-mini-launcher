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
var json_name: String
var game_jsons: PackedStringArray
var games: DirAccess
var folder_name: String

var game_folder: String
var game_exec_path: String
var game_thumbnail_path: String
var thumbnail_texture: Texture2D
var resized_thumbnail: Image
var game_folder_contents: PackedStringArray

var game_button: Button
var json_string: String
var json_dict: Dictionary

var info_name
var info_genres
var info_author
var info_description

var game_running: bool = false
var running_pid: int = -1
var connected = false

var buttons: Array = []  # 2D array to hold buttons

var panel_updated : bool = false

func _process(_delta: float) -> void:
	# Prevents more than one game from being launched at a time
	if game_running and not OS.is_process_running(running_pid):
		game_running = false

func _ready() -> void:
	# Initialize variables
	info_panel.visible = false
	selected_game.visible = false
	play_focus.visible = false
	buttons.clear()

	# Collect JSON file names
	jsons = DirAccess.open(JSON_DIR)
	game_jsons = PackedStringArray()
	if jsons:
		jsons.list_dir_begin()
		json_name = jsons.get_next()
		while json_name != "":
			if json_name.ends_with(".json"):
				game_jsons.append(json_name.get_basename())
			json_name = jsons.get_next()
	game_jsons.sort()

	# Collect and sort folder names
	var folder_names = []
	games = DirAccess.open(GAME_DIR)
	if games:
		games.list_dir_begin()
		folder_name = games.get_next()
		while folder_name != "":
			if games.current_is_dir() and not folder_name.begins_with("."):
				folder_names.append(folder_name)
			folder_name = games.get_next()
	folder_names.sort()

	# Create buttons for game folders
	var row = []
	for folder_name in folder_names:
		if game_jsons.has(folder_name):
			game_folder = GAME_DIR + folder_name
			game_exec_path = game_folder + "/" + folder_name + ".x86_64"
			game_thumbnail_path = game_folder + "/" + folder_name + ".png"

			# Create the button
			game_button = Button.new()
			game_button.set_flat(true)
			var style_box = StyleBoxFlat.new()
			game_button.add_theme_stylebox_override("normal", style_box)
			game_button.add_theme_stylebox_override("hover", style_box)
			game_button.add_theme_stylebox_override("pressed", style_box)
			game_button.add_theme_stylebox_override("focused", style_box)
			game_button.set_meta("exec_path", game_exec_path)

			# Read JSON data
			var json_file = FileAccess.open(JSON_DIR + folder_name + ".json", FileAccess.READ)
			if json_file:
				json_string = json_file.get_as_text()
				var json = JSON.new()
				if json.parse(json_string) == OK:
					var data = json.get_data()
					game_button.set_meta("name", data.get("name", "Unknown"))
					game_button.set_meta("author", data.get("author", "Unknown"))
					game_button.set_meta("description", data.get("description", "No description available"))
					game_button.set_meta("genres", data.get("genres", "Unknown"))

			# Add thumbnail to the button
			thumbnail_texture = load(game_thumbnail_path)
			resized_thumbnail = thumbnail_texture.get_image()
			resized_thumbnail.resize(235, 187)
			game_button.icon = ImageTexture.create_from_image(resized_thumbnail)

			# Add button to grid and row
			game_grid.add_child(game_button)
			row.append(game_button)
			if row.size() == 2:
				buttons.append(row)
				row = []

			# Connect signals for interaction
			game_button.connect("pressed", update_info_panel.bind(game_button))
			game_button.connect("mouse_entered", focus_button.bind(game_button))
			game_button.connect("focus_entered", focus_button.bind(game_button))
			
	if row.size() > 0:
		buttons.append(row)  # Add any remaining buttons

	# Set the neighbors for each button
	set_neighbors(buttons)
	
	game_grid.get_child(0).grab_focus()
	play_button.focus_neighbor_left = game_grid.get_child(0).get_path()

func set_neighbors(buttons: Array) -> void:
	for row_index in range(buttons.size()):
		var row = buttons[row_index]
		for col_index in range(row.size()):
			var button = row[col_index]
			var neighbor
			# Set the neighbors for the button (left, right, top, bottom)
			
			# Button has a neighbor to the left
			if col_index > 0:
				neighbor = row[col_index - 1]
				button.focus_neighbor_left = neighbor.get_path()

			# Button has a neighbor to the right
			if col_index < row.size() - 1:
				neighbor = row[col_index + 1]
				button.focus_neighbor_right = neighbor.get_path()

			# For right column buttons, set the right neighbor to $info_panel/play_button
			if col_index == row.size() - 1:
				button.focus_neighbor_right = $info_panel/play_button.get_path()

			# Button has a neighbor above
			if row_index > 0 and col_index < buttons[row_index - 1].size():
				neighbor = buttons[row_index - 1][col_index]
				button.focus_neighbor_top = neighbor.get_path()

			# Button has a neighbor below
			if row_index < buttons.size() - 1 and col_index < buttons[row_index + 1].size():
				neighbor = buttons[row_index + 1][col_index]
				button.focus_neighbor_bottom = neighbor.get_path()


# Highlight the selected game on hover
func focus_button(button: Button) -> void:
	selected_game.visible = true
	selected_game.global_position = button.global_position

# Remove highlight on hover exit
func unfocus_button(_button: Button) -> void:
	selected_game.visible = false

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
	var exec_path = button.get_meta("exec_path")
	if exec_path:
		running_pid = OS.create_process(exec_path, [])
		game_running = true
	else:
		print("No exec path found for button: ", button.name)

func _on_play_button_focus_entered() -> void:
	if panel_updated:
		selected_game.visible = false
		play_focus.visible = true

func _on_play_button_focus_exited() -> void:
	selected_game.visible = true
	play_focus.visible = false
