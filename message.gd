class_name MessageScene extends Node2D

var nextbar: Nextbar
const NEXTBAR_POSITION: Vector2 = Vector2(0, 0)

func _ready() -> void:
	nextbar = preload("res://nextbar.tscn").instantiate()
	nextbar.set_level_name("")
	add_child(nextbar)
	nextbar.global_position = NEXTBAR_POSITION

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mousepos: Vector2 = get_global_mouse_position()
		if !nextbar.bg_rect.get_rect().has_point(nextbar.to_local(mousepos)):
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				Manager.next_level()
