class_name Toolbar extends Node2D

func contains_mouse(mousepos: Vector2i) -> bool:
	return $ColorRect.get_rect().has_point(to_local(mousepos))

func set_tool_text(text: String):
	$ToolText.text  = text
