extends Node

# TODO (sam): sort of ripping puzzlescript here. we will just go through scenes, check if "completed"
#             (if they are info text, then thats just a button press), and go next.
#
# game flow:
# - title screen
# - if not played: give disclaimer.
# - after clicking thru disclaimer: land on first puzzle of chapter 1. at this point, savegame.
# - save game at prev/next level, or tool usage.
# - first level in chapter 1 won't have prev.
# - last level in chapter won't have next available until all puzzles are solved.
# - can have textual interludes, perhaps: either on first time in a garden? (skip after), or between chapters.
# 
# thoughts/questions:
# - where does the snake fit in??
# - would be interesting if the game could flip like pages in a book on transition..
#   - generally maybe want some sort of transition that is not just _switch_. idk. this isnt hard generally
# 
# per-level, need to save:
# - current WorldTiles data
# - current tool selection
# - current inventory
# - is_solved (maybe, for fast access...)
#
# game-wise, need to save:
# - furthest_chapter
# - current_chapter
# - current_level_in_chapter
# 
# TODO: how should we handle eg. undoing a solution, after it's correct??
# disallow progression again?
#
# how do we map what a level is to its data?
# just save the scene ID of it??

var chapters := [
	# intro text
	{
		"intro01": "res://gardens/ch1/text1.tscn",
		"intro02": "res://gardens/ch1/text1a.tscn",
		"intro03": "res://gardens/ch1/text1b.tscn",
		"intro04": "res://gardens/ch1/text1c.tscn",
		"intro05": "res://gardens/ch1/text1d.tscn",
		"intro06": "res://gardens/ch1/text1e.tscn",
		"intro07": "res://gardens/ch1/text1f.tscn",
		"intro08": "res://gardens/ch1/text1g1.tscn",
		"intro09": "res://gardens/ch1/text1g2.tscn",
		"intro10": "res://gardens/ch1/text1h.tscn",
		"intro11": "res://gardens/ch1/text1i.tscn",
	},
	
	# "chapter 1"
	{
		"yard A": "res://gardens/ch2/garden_rose1.tscn",
		"yard B": "res://gardens/ch2/garden_rose2.tscn",
		"yard C": "res://gardens/ch2/garden_rose3.tscn",
		"yard D": "res://gardens/ch2/garden_rose4.tscn",
		"yard E": "res://gardens/ch2/garden_rose_apart2.tscn",
		"yard F": "res://gardens/ch2/garden_sunny1.tscn",
		"yard G": "res://gardens/ch2/garden_sunny2.tscn",
		"yard H": "res://gardens/ch2/garden_sunny3.tscn",
		"yard I": "res://gardens/ch2/garden_sunny4.tscn",
		"yard J": "res://gardens/ch2/garden_sunny5.tscn",
		"yard K": "res://gardens/ch2/garden_rs1.tscn",
		"yard L": "res://gardens/ch2/garden_extra1.tscn",
		"yard M": "res://gardens/ch2/garden_extra2.tscn",
		"yard N": "res://gardens/ch2/garden_extra3.tscn",
	},
	
	# transition
	{
		"trans_1_01": "res://gardens/ch3/text1.tscn",
		"trans_1_02": "res://gardens/ch3/text2.tscn",
		"trans_1_03": "res://gardens/ch3/text3.tscn",
		"trans_1_04": "res://gardens/ch3/text4.tscn",
		"trans_1_05": "res://gardens/ch3/text5.tscn",
		"trans_1_06": "res://gardens/ch3/text6.tscn",
		"trans_1_07": "res://gardens/ch3/text7.tscn",
	},
	
	# "chapter 2" (lavenders)
	{
		"grove A": "res://gardens/ch4/garden_lav1.tscn",
		"grove B": "res://gardens/ch4/garden_lav2.tscn",
		"grove C": "res://gardens/ch4/garden_lav3.tscn",
		"grove D": "res://gardens/ch4/garden_lav4.tscn",
		"grove E": "res://gardens/ch4/garden_lav4a.tscn",
		"grove F": "res://gardens/ch4/garden_lav5.tscn",
		"grove G": "res://gardens/ch4/garden_lav6.tscn",
		"grove H": "res://gardens/ch4/garden_lav7.tscn",
		"grove I": "res://gardens/ch4/garden_lav8.tscn",
		"grove J": "res://gardens/ch4/garden_lav9.tscn",
		"grove K": "res://gardens/ch4/garden_lav10.tscn",
		"grove L": "res://gardens/ch4/garden_lav11.tscn",
		"grove M": "res://gardens/ch4/garden_lav12.tscn",
		"grove N": "res://gardens/ch4/garden_lav13.tscn",
	},
	
	# transition
	{
		"trans_2_01": "res://gardens/ch5/text1.tscn",
		"trans_2_02": "res://gardens/ch5/text2.tscn",
		"trans_2_03": "res://gardens/ch5/text3.tscn",
		"trans_2_04": "res://gardens/ch5/text4.tscn",
		"trans_2_05": "res://gardens/ch5/text5.tscn",
		"trans_2_06": "res://gardens/ch5/text6.tscn",
		"trans_2_07": "res://gardens/ch5/text7.tscn",
		"trans_2_08": "res://gardens/ch5/text8.tscn",
	},
	
	# "chapter 3" (morning glories)
	{
		"trellis A": "res://gardens/ch6/garden_glory1.tscn",
		"trellis B": "res://gardens/ch6/garden_glory2.tscn",
		"trellis C": "res://gardens/ch6/garden_glory3.tscn",
		"trellis D": "res://gardens/ch6/garden_glory4.tscn",
		"trellis E": "res://gardens/ch6/garden_glory5.tscn",
		"trellis F": "res://gardens/ch6/garden_glory7.tscn",
		"trellis G": "res://gardens/ch6/garden_glory8.tscn",
		"trellis H": "res://gardens/ch6/garden_glory8a.tscn",
		"trellis I": "res://gardens/ch6/garden_glory9.tscn",
		"trellis J": "res://gardens/ch6/garden_synthesis1.tscn",
		"trellis K": "res://gardens/ch6/garden_synthesis2.tscn",
		"trellis L": "res://gardens/ch6/garden_glory11.tscn",
		"trellis M": "res://gardens/ch6/garden_final.tscn",
	},
	
	# transition....
	{
		"end_01": "res://gardens/ch7/text1.tscn",
		"end_02": "res://gardens/ch7/text2.tscn",
		"end_03": "res://gardens/ch7/text3.tscn",
		"end_04": "res://gardens/ch7/text4.tscn",
		"end_05": "res://gardens/ch7/text5.tscn",
	},
]
# TODO: maybe shouldn't update these until we actually complete a load... idk
var furthest_chapter := 0
var current_chapter := 0
var current_level_in_chapter := 0
var chapters_which_need_levels_saved := [1, 3, 5]

class LevelData:
	var was_this_level_saved: bool = false
	var level_name: String
	var tiles: PackedByteArray
	var current_tool: int
	var current_inventory: Dictionary[int, int]
	var all_planted: bool
	var is_solved: bool
	
	func serialize() -> Dictionary:
		return {
			"was_this_level_saved": was_this_level_saved,
			"level_name": level_name,
			"tiles": Marshalls.raw_to_base64(tiles),
			"current_tool": current_tool,
			"current_inventory": current_inventory,
			"all_planted": all_planted,
			"is_solved": is_solved,
		}
	
	static func deserialize(data: Dictionary) -> LevelData:
		var level_data: LevelData = LevelData.new()
		
		level_data.was_this_level_saved = data.get("was_this_level_saved", false)
		level_data.level_name = data.get("level_name", "")
		
		var tile_string: String = data.get("tiles", "")
		level_data.tiles = Marshalls.base64_to_raw(tile_string)
		
		level_data.current_tool = data.get("current_tool", 0)
		
		var raw_inventory: Dictionary = data.get("current_inventory", {})
		level_data.current_inventory = {}
		for key in raw_inventory.keys():
			level_data.current_inventory[int(key)] = int(raw_inventory[key])
		
		level_data.all_planted = data.get("all_planted", false)
		level_data.is_solved = data.get("is_solved", false)
		
		return level_data

var level_saves: Dictionary[String, LevelData] = {}

enum State {
	MAIN_MENU,
	LOADING_LEVEL,
	IN_LEVEL,
}
var current_state: State = State.MAIN_MENU
# maybe a misnomer, but just the "wait time" before level transition, so you can take in that you won or w/e.
# akin to victory screen/fadeout
var load_minimum_time: float = 0
var load_minimum_timer: float = 0

var currently_loading_chapter: int = 0
var currently_loading_level: int = 0


var is_mobile_device: bool = false


func _ready() -> void:
	if OS.has_feature("web_android") or OS.has_feature("web_ios"):
		is_mobile_device = true
	# TODO (sam): persistent save sessions (eg. write to disk)
	for ch in chapters_which_need_levels_saved:
		for level_name in chapters[ch].keys():
			level_saves[level_name] = LevelData.new()
			level_saves[level_name].level_name = level_name


func _process(delta: float) -> void:
	if current_state == State.LOADING_LEVEL:
		load_minimum_timer -= delta
		if load_minimum_timer <= 0 and ResourceLoader.load_threaded_get_status(chapters[currently_loading_chapter].values()[currently_loading_level]) == 3:
			var scene: PackedScene = ResourceLoader.load_threaded_get(chapters[currently_loading_chapter].values()[currently_loading_level])
			var level := scene.instantiate()
			get_tree().change_scene_to_node(level)
			
			current_chapter = currently_loading_chapter
			current_level_in_chapter = currently_loading_level
			
			current_state = State.IN_LEVEL
			
			save_game()

func load_level_in_background(chapter: int, level: int) -> void:
	ResourceLoader.load_threaded_request(chapters[chapter].values()[level])
	current_state = State.LOADING_LEVEL
	load_minimum_timer = load_minimum_time

func chapter_cleared(chapter: int) -> bool:
	if chapter not in chapters_which_need_levels_saved:
		return true
	
	for level_name in chapters[chapter].keys():
		if not level_saves[level_name].is_solved:
			return false
	return true

func current_chapter_cleared() -> bool:
	return chapter_cleared(current_chapter)

func current_level_name() -> String:
	return chapters[current_chapter].keys()[current_level_in_chapter]

func all_seeds_placed(chapter: int) -> bool:
	for level_name in chapters[chapter].keys():
		if !level_saves[level_name].all_planted:
				return false
	return true

func prev_chapter() -> void:
	MusicManager.sfx_click_button_negative()
	if current_level_in_chapter > 0:
		currently_loading_chapter = current_chapter
		currently_loading_level = 0
		load_level_in_background(currently_loading_chapter, currently_loading_level)
	elif current_level_in_chapter == 0:
		if current_chapter > 0:
			currently_loading_chapter = current_chapter - 1
			currently_loading_level = 0
			load_level_in_background(currently_loading_chapter, currently_loading_level)
		else:
			get_tree().change_scene_to_file("res://title.tscn")
			return

func next_chapter() -> void:
	if current_chapter < chapters.size():
		MusicManager.sfx_click_button_positive()
		if (
			current_chapter == furthest_chapter 
			and current_chapter in chapters_which_need_levels_saved
		):
			go_to_hint_zone()
		else:
			currently_loading_chapter = current_chapter + 1
			currently_loading_level = 0
			furthest_chapter = max(furthest_chapter, currently_loading_chapter)
			load_level_in_background(currently_loading_chapter, currently_loading_level)
	else:
		print("hit last chapter!")
		return

func prev_level() -> void:
	MusicManager.sfx_click_button_negative()
	if current_level_in_chapter > 0:
		currently_loading_level = current_level_in_chapter - 1
		load_level_in_background(current_chapter, currently_loading_level)
	elif current_chapter > 0:
		currently_loading_chapter = current_chapter - 1
		currently_loading_level = chapters[currently_loading_chapter].size() - 1
		load_level_in_background(currently_loading_chapter, currently_loading_level)
	else:
		get_tree().change_scene_to_file("res://title.tscn")
		return

func next_level(bypass_hintzone: bool = false) -> void:
	if on_last_level():
		return
	
	MusicManager.sfx_click_button_positive()
	if current_level_in_chapter < chapters[current_chapter].size() - 1:
		currently_loading_level = current_level_in_chapter + 1
		load_level_in_background(current_chapter, currently_loading_level)
	elif current_chapter < chapters.size():
		if (
			current_chapter == furthest_chapter 
			and current_chapter in chapters_which_need_levels_saved
			and !bypass_hintzone
		):
			go_to_hint_zone()
		else:
			currently_loading_chapter = current_chapter + 1
			currently_loading_level = 0
			furthest_chapter = max(furthest_chapter, currently_loading_chapter)
			load_level_in_background(currently_loading_chapter, currently_loading_level)
	else:
		print("hit end of levels!")
		return
	
	save_game()


func on_first_level() -> bool:
	return current_chapter == 0 and current_level_in_chapter == 0

func on_last_chapter() -> bool:
	return current_chapter == (chapters.size() - 1)

func on_last_level() -> bool:
	return on_last_chapter() and current_level_in_chapter == (chapters[current_chapter].size() - 1)

func go_to_hint_zone() -> void:
	if all_seeds_placed(current_chapter):
		get_tree().change_scene_to_file("res://hintzone/check_chapter.tscn")
	else:
		get_tree().change_scene_to_file("res://hintzone/seed_warning_check.tscn")

func go_to_level_in_current_chapter(level: int) -> void:
	assert(level < chapters[current_chapter].size(), "target level out of bounds for chapter %d" % current_chapter)
	currently_loading_chapter = current_chapter
	currently_loading_level = level
	load_level_in_background(currently_loading_chapter, currently_loading_level)

func exit_hint_zone() -> void:
	load_level_in_background(current_chapter, current_level_in_chapter)

func save_level(tiles: PackedByteArray, level_name: String, current_tool: int, current_inventory: Dictionary[int, int], all_planted: bool, is_solved: bool) -> void:
	if level_name in level_saves:
		level_saves[level_name].was_this_level_saved = true
		level_saves[level_name].level_name = level_name
		level_saves[level_name].tiles = tiles
		level_saves[level_name].current_tool = current_tool
		level_saves[level_name].current_inventory = current_inventory
		level_saves[level_name].all_planted = all_planted
		level_saves[level_name].is_solved = is_solved

func load_level(level_name: String) -> LevelData:
	if level_name in level_saves:
		if level_saves[level_name].was_this_level_saved:
			return level_saves[level_name]
		else:
			return null
	else:
		return null

func save_game() -> void:
	# need to save:
	# - level_saves dict
	# - furthest_chapter
	# - current_chapter
	# - current_level_in_chapter
	var serialized_level_saves: Dictionary = {}
	for level_name: String in level_saves.keys():
		if level_saves[level_name].was_this_level_saved:
			serialized_level_saves[level_name] = level_saves[level_name].serialize()
	var save_dict := {
		"level_saves": serialized_level_saves,
		"furthest_chapter": furthest_chapter,
		"current_chapter": current_chapter,
		"current_level_in_chapter": current_level_in_chapter,
		"mus_vol": AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Music")),
		"sfx_vol": AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("SFX")),
	}
	# open file
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var json_string = JSON.stringify(save_dict)
	#print("saving json: ", json_string)
	save_file.store_line(json_string)

func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.save"):
		print("no save to load")
		return
	# open file
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	var json_string = save_file.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if not parse_result == OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
		return
	# get the data
	var save_data = json.data
	#print("loaded data: ", save_data)
	# update game state based on loaded data
	var saved_level_saves: Dictionary = save_data["level_saves"]
	for level_name: String in saved_level_saves.keys():
		level_saves[level_name] = LevelData.deserialize(saved_level_saves[level_name])
	furthest_chapter = save_data["furthest_chapter"]
	current_chapter = save_data["current_chapter"]
	current_level_in_chapter = save_data["current_level_in_chapter"]
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Music"), save_data["mus_vol"])
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), save_data["sfx_vol"])


func delete_game() -> void:
	if not FileAccess.file_exists("user://savegame.save"):
		print("no save to delete")
		return
	DirAccess.remove_absolute("user://savegame.save")
	level_saves = {}
	for ch in chapters_which_need_levels_saved:
		for level_name in chapters[ch].keys():
			level_saves[level_name] = LevelData.new()
			level_saves[level_name].level_name = level_name
	furthest_chapter = 0
	current_chapter = 0
	current_level_in_chapter = 0

func restart_game() -> void:
	get_tree().change_scene_to_file("res://title.tscn")

func new_game() -> void:
	current_chapter = 0
	current_level_in_chapter = 0
	load_level_in_background(0, 0)

## call after loading game data with load_game()
func continue_game() -> void:
	currently_loading_chapter = current_chapter
	currently_loading_level = current_level_in_chapter
	load_level_in_background(current_chapter, current_level_in_chapter)


#region click here indicator

var has_clicked_tool: bool = false

#endregion
