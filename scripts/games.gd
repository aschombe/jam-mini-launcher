extends Resource
class_name Game

@export var exec_path : String = ""
@export var game_title: String = "Default Game Title"
@export var author: Array[String] = ["Default Author"]
@export var genres: Array[String] = ["Default genre"]
@export var description: String = "Default description of game"
@export var type : String = "SinglePlayer" #player count
@export var creation_year : String = "1980"
@export var grad_year: String = "0001"

@export var folder_path : String = ""

@export var texture : Texture = null
@export var video : VideoStream = null

func loadFromJsonDict(dict):
	game_title = dict.name
	author.assign(dict.author.rsplit(',',false,1))
	genres.assign(dict.genres.rsplit(',',false,1))
	description = dict.description
	type = dict.type
	creation_year = dict.creation_year
	grad_year = dict.grad_year

func _to_string() -> String:
	return self.game_title
