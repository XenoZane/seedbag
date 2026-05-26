extends Node2D

enum HintzoneBehavior {NONE, CHECK_CHAPTER, SHOW_HINT, IS_HINT, ALL_CORRECT}

@export var my_behavior: HintzoneBehavior = HintzoneBehavior.NONE

@onready var level_text: RichTextLabel = $Infobar/LevelText

var first_incomplete_level_idx: int = 99999


func _ready() -> void:
	MusicManager.sfx_dialog_advance()
	if my_behavior == HintzoneBehavior.IS_HINT:
		var first_incomplete_level_in_chapter: String = "???"
		for idx in Manager.chapters[Manager.current_chapter].size():
			var level_name: String = Manager.chapters[Manager.current_chapter].keys()[idx]
			if not Manager.level_saves[level_name].is_solved:
				first_incomplete_level_in_chapter = Manager.level_saves[level_name].level_name
				first_incomplete_level_idx = idx
				break
		$Message.text = $Message.text.replace("<garden>", "[color=#ff0000]%s[/color]" % first_incomplete_level_in_chapter)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("left") and my_behavior != HintzoneBehavior.ALL_CORRECT:
		Manager.exit_hint_zone()

func _on_back_button_pressed() -> void:
	MusicManager.sfx_click_button_negative()
	Manager.exit_hint_zone()
	
func _on_the_hint_back_button_pressed() -> void:
	MusicManager.sfx_click_button_negative()
	Manager.go_to_level_in_current_chapter(first_incomplete_level_idx)

func _on_check_button_pressed() -> void:
	match my_behavior:
		HintzoneBehavior.NONE:
			pass
		HintzoneBehavior.IS_HINT:
			pass
		HintzoneBehavior.CHECK_CHAPTER:
			Manager.save_game()
			if Manager.current_chapter_cleared():
				get_tree().change_scene_to_file("res://hintzone/all_correct.tscn")
				MusicManager.sfx_check_puzzle_correct()
			else:
				get_tree().change_scene_to_file("res://hintzone/want_a_hint.tscn")
				MusicManager.sfx_check_puzzle_wrong()
		HintzoneBehavior.SHOW_HINT:
			MusicManager.sfx_click_button_neutral()
			get_tree().change_scene_to_file("res://hintzone/the_hint.tscn")
		HintzoneBehavior.ALL_CORRECT:
			MusicManager.sfx_click_button_positive()
			Manager.current_level_in_chapter = Manager.chapters[Manager.current_chapter].size() - 1
			Manager.next_level(true)


func _on_back_button_mouse_entered() -> void:
	level_text.text = "return to gardens"
	MusicManager.sfx_hover_button()

func _on_back_button_mouse_exited() -> void:
	level_text.text = ""

func _on_check_button_mouse_entered() -> void:
	match my_behavior:
		HintzoneBehavior.NONE:
			level_text.text = ""
		HintzoneBehavior.IS_HINT:
			level_text.text = ""
		HintzoneBehavior.CHECK_CHAPTER:
			level_text.text = "check yer work"
		HintzoneBehavior.SHOW_HINT:
			level_text.text = "gimme a hint"
		HintzoneBehavior.ALL_CORRECT:
			level_text.text = "bingo!"
	MusicManager.sfx_hover_button()

func _on_check_button_mouse_exited() -> void:
	level_text.text = ""
