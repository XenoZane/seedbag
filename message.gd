extends Node2D

signal complete

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("action"):
		complete.emit()
