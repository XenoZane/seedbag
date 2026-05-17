class_name Toolbar extends Node2D

var amount_labels: Dictionary[Garden.Tool, RichTextLabel]

func contains_mouse(mousepos: Vector2i) -> bool:
	return $ColorRect.get_rect().has_point(to_local(mousepos))

func set_tool_text(text: String):
	$ToolText.text  = text

func add_amount_label(global_pos: Vector2, amount: int, tool: Garden.Tool) -> void:
	var new_label: RichTextLabel = $TextTemplate.duplicate()
	add_child(new_label)
	new_label.text = str(amount)
	new_label.global_position = global_pos
	amount_labels[tool] = new_label
