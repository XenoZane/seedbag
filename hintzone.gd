extends Node2D

func _ready() -> void:
	var first_incomplete_level_in_chapter: String = "???"
	for path in Manager.chapters[Manager.current_chapter]:
		if not Manager.level_saves[path].is_solved:
			first_incomplete_level_in_chapter = Manager.level_saves[path].level_name
			break
	$Message.text = $Message.text.replace("<garden>", "[color=#ff0000]%s[/color]" % first_incomplete_level_in_chapter)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			Manager.exit_hint_zone()
