extends Node

# TODO (sam): sort of ripping puzzlescript here. we will just go through scenes, check if "completed"
#             (if they are info text, then thats just a button press), and go next.
var levels := [
	"res://levels/text1.tscn",
	"res://levels/trample_easy.tscn",
	"res://levels/trample_another.tscn",
	"res://levels/trample_4corners.tscn",
	"res://levels/trample_3corners.tscn",
	"res://levels/trample_II.tscn",
	"res://levels/text2.tscn",
]
var current_level := 0

enum State {
	MAIN_MENU,
	LOADING_LEVEL,
	IN_LEVEL,
}
var current_state: State = State.MAIN_MENU
var currently_loading_level: int = 0
# maybe a misnomer, but just the "wait time" before level transition, so you can take in that you won or w/e.
# akin to victory screen/fadeout
var load_minimum_time: float = 0.2
var load_minimum_timer: float = 0

# TODO (sam): should we also save undo stack? we _could_. might be nice?

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if current_state == State.LOADING_LEVEL:
		load_minimum_timer -= delta
		if load_minimum_timer <= 0 and ResourceLoader.load_threaded_get_status(levels[currently_loading_level]) == 3:
			var scene: PackedScene = ResourceLoader.load_threaded_get(levels[currently_loading_level])
			var level := scene.instantiate()
			level.complete.connect(_on_level_complete)
			get_tree().change_scene_to_node(level)
			
			# might not be necessary...
			current_level = currently_loading_level

func load_level_in_background(idx: int) -> void:
	ResourceLoader.load_threaded_request(levels[idx])
	currently_loading_level = idx
	current_state = State.LOADING_LEVEL
	load_minimum_timer = load_minimum_time

func _on_level_complete() -> void:
	current_level += 1
	if current_level < levels.size():
		save_game()
		load_level_in_background(current_level)
	else:
		get_tree().change_scene_to_file("res://levels/title.tscn")

func save_game() -> void:
	var savefile := FileAccess.open("user://seedbag.save", FileAccess.WRITE)
	
	# if we won, store penultimate level.
	if current_level == levels.size() - 1:
		savefile.store_64(current_level - 1)
	else:
		savefile.store_64(current_level)

func new_game() -> void:
	load_level_in_background(0)

func continue_game() -> void:
	var savefile: FileAccess = FileAccess.open("user://seedbag.save", FileAccess.READ)
	current_level = savefile.get_64()
	load_level_in_background(current_level)
