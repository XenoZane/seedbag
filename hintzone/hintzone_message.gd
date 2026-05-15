extends Node2D

enum HintzoneBehavior {NONE, CHECK_CHAPTER, SHOW_HINT, IS_HINT, ALL_CORRECT}

@export var my_behavior: HintzoneBehavior = HintzoneBehavior.NONE

@onready var level_text: RichTextLabel = $Infobar/LevelText


func _ready() -> void:
	if my_behavior == HintzoneBehavior.IS_HINT:
		var first_incomplete_level_in_chapter: String = "???"
		for path in Manager.chapters[Manager.current_chapter]:
			if not Manager.level_saves[path].is_solved:
				first_incomplete_level_in_chapter = Manager.level_saves[path].level_name
				break
		$Message.text = $Message.text.replace("<garden>", "[color=#ff0000]%s[/color]" % first_incomplete_level_in_chapter)


func _on_back_button_pressed() -> void:
	Manager.exit_hint_zone()


func _on_check_button_pressed() -> void:
	match my_behavior:
		HintzoneBehavior.NONE:
			pass
		HintzoneBehavior.IS_HINT:
			pass
		HintzoneBehavior.CHECK_CHAPTER:
			if Manager.current_chapter_cleared():
				get_tree().change_scene_to_file("res://hintzone/all_correct.tscn")
			else:
				get_tree().change_scene_to_file("res://hintzone/want_a_hint.tscn")
		HintzoneBehavior.SHOW_HINT:
			get_tree().change_scene_to_file("res://hintzone/the_hint.tscn")
		HintzoneBehavior.ALL_CORRECT:
			Manager.next_level(true)


func _on_back_button_mouse_entered() -> void:
	level_text.text = "return to gardens"

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

func _on_check_button_mouse_exited() -> void:
	level_text.text = ""
