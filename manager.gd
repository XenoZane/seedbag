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
	[
		"res://gardens/ch1/text1.tscn",
		"res://gardens/ch1/text1a.tscn",
		"res://gardens/ch1/text1b.tscn",
		"res://gardens/ch1/text1c.tscn",
		"res://gardens/ch1/text1d.tscn",
		"res://gardens/ch1/text1e.tscn",
		"res://gardens/ch1/text1f.tscn",
		"res://gardens/ch1/text1g.tscn",
		"res://gardens/ch1/text1h.tscn",
		"res://gardens/ch1/text1i.tscn",
	],
	
	# "chapter 1"
	[
		"res://gardens/ch2/garden_rose1.tscn",
		"res://gardens/ch2/garden_rose2.tscn",
		"res://gardens/ch2/garden_rose3.tscn",
		"res://gardens/ch2/garden_rose4.tscn",
		"res://gardens/ch2/garden_sunny1.tscn",
		"res://gardens/ch2/garden_sunny2.tscn",
		"res://gardens/ch2/garden_sunny3.tscn",
		"res://gardens/ch2/garden_rs1.tscn",
		"res://gardens/ch2/garden_extra1.tscn",
		"res://gardens/ch2/garden_extra2.tscn",
		"res://gardens/ch2/garden_extra3.tscn",
	],
	
	# transition
	[
		"res://gardens/ch3/text1.tscn",
		"res://gardens/ch3/text2.tscn",
		"res://gardens/ch3/text3.tscn",
		"res://gardens/ch3/text4.tscn",
		"res://gardens/ch3/text5.tscn",
		"res://gardens/ch3/text6.tscn",
		"res://gardens/ch3/text7.tscn",
	],
	
	# "chapter 2" (lavenders)
	[
		"res://gardens/ch4/garden_lav1.tscn",
		"res://gardens/ch4/garden_lav2.tscn",
		"res://gardens/ch4/garden_lav3.tscn",
		"res://gardens/ch4/garden_lav4.tscn",
		"res://gardens/ch4/garden_lav5.tscn",
		"res://gardens/ch4/garden_lav6.tscn",
		"res://gardens/ch4/garden_lav7.tscn",
		"res://gardens/ch4/garden_lav8.tscn",
		"res://gardens/ch4/garden_lav9.tscn",
		"res://gardens/ch4/garden_lav10.tscn",
		"res://gardens/ch4/garden_lav11.tscn",
	],
	
	# transition
	[
		"res://gardens/ch5/text1.tscn",
		"res://gardens/ch5/text2.tscn",
		"res://gardens/ch5/text3.tscn",
		"res://gardens/ch5/text4.tscn",
		"res://gardens/ch5/text5.tscn",
		"res://gardens/ch5/text6.tscn",
		"res://gardens/ch5/text7.tscn",
		"res://gardens/ch5/text8.tscn",
	],
	
	# "chapter 3" (morning glories)
	[
		"res://gardens/ch6/garden_glory1.tscn",
		"res://gardens/ch6/garden_glory2.tscn",
		"res://gardens/ch6/garden_glory3.tscn",
		"res://gardens/ch6/garden_glory4.tscn",
		"res://gardens/ch6/garden_glory5.tscn",
		"res://gardens/ch6/garden_glory7.tscn",
		"res://gardens/ch6/garden_glory8.tscn",
		"res://gardens/ch6/garden_glory9.tscn",
	],
	
	# transition....
	[
		"res://gardens/ch7/text1.tscn",
	],
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
	var is_solved: bool

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


func _ready() -> void:
	# TODO (sam): persistent save sessions (eg. write to disk)
	for ch in chapters_which_need_levels_saved:
		for level in chapters[ch]:
			level_saves[level] = LevelData.new()

func _process(delta: float) -> void:
	if current_state == State.LOADING_LEVEL:
		load_minimum_timer -= delta
		if load_minimum_timer <= 0 and ResourceLoader.load_threaded_get_status(chapters[currently_loading_chapter][currently_loading_level]) == 3:
			var scene: PackedScene = ResourceLoader.load_threaded_get(chapters[currently_loading_chapter][currently_loading_level])
			var level := scene.instantiate()
			get_tree().change_scene_to_node(level)
			
			current_chapter = currently_loading_chapter
			current_level_in_chapter = currently_loading_level
			
			current_state = State.IN_LEVEL

func load_level_in_background(chapter: int, level: int) -> void:
	ResourceLoader.load_threaded_request(chapters[chapter][level])
	current_state = State.LOADING_LEVEL
	load_minimum_timer = load_minimum_time

func chapter_cleared(chapter: int) -> bool:
	if chapter not in chapters_which_need_levels_saved:
		return true
	
	for level in chapters[chapter]:
		if not level_saves[level].is_solved:
			return false
	return true

func prev_chapter() -> void:
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
			print("hit first chapter!")
			return

func next_chapter() -> void:
	if current_chapter < chapters.size():
		if (
			current_chapter == furthest_chapter 
			and current_chapter in chapters_which_need_levels_saved 
			and not chapter_cleared(current_chapter)
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
	if current_level_in_chapter > 0:
		currently_loading_level = current_level_in_chapter - 1
		load_level_in_background(current_chapter, currently_loading_level)
	elif current_chapter > 0:
		currently_loading_chapter = current_chapter - 1
		currently_loading_level = chapters[currently_loading_chapter].size() - 1
		load_level_in_background(currently_loading_chapter, currently_loading_level)
	else:
		print("hit beginning of levels!")
		return
		

func next_level() -> void:
	if current_level_in_chapter < chapters[current_chapter].size() - 1:
		currently_loading_level = current_level_in_chapter + 1
		load_level_in_background(current_chapter, currently_loading_level)
	elif current_chapter < chapters.size():
		if (
			current_chapter == furthest_chapter 
			and current_chapter in chapters_which_need_levels_saved 
			and not chapter_cleared(current_chapter)
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

func on_first_level() -> bool:
	return current_chapter == 0 and current_level_in_chapter == 0

func on_last_chapter() -> bool:
	return current_chapter == (chapters.size() - 1)

func on_last_level() -> bool:
	return on_last_chapter() and current_level_in_chapter == (chapters[current_chapter].size() - 1)

func go_to_hint_zone() -> void:
	get_tree().change_scene_to_file("res://hintzone.tscn")

func exit_hint_zone() -> void:
	load_level_in_background(current_chapter, current_level_in_chapter)

func save_level(tiles: PackedByteArray, level_name: String, current_tool: int, current_inventory: Dictionary[int, int], is_solved: bool) -> void:
	var level_file_path: String = chapters[current_chapter][current_level_in_chapter]
	if level_file_path in level_saves:
		level_saves[level_file_path].was_this_level_saved = true
		level_saves[level_file_path].level_name = level_name
		level_saves[level_file_path].tiles = tiles
		level_saves[level_file_path].current_tool = current_tool
		level_saves[level_file_path].current_inventory = current_inventory
		level_saves[level_file_path].is_solved = is_solved

func load_level(path: String) -> LevelData:
	if path in level_saves:
		if level_saves[path].was_this_level_saved:
			return level_saves[path]
		else:
			return null
	else:
		return null

func save_game() -> void:
	return

func load_game() -> void:
	return

func new_game() -> void:
	current_chapter = 0
	current_level_in_chapter = 0
	load_level_in_background(0, 0)

func continue_game() -> void:
	return
