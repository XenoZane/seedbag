extends Node2D

@onready var nextbar: Nextbar = $Nextbar

func _ready() -> void:
	nextbar.set_level_name("")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mousepos: Vector2 = get_global_mouse_position()
		if !nextbar.bg_rect.get_rect().has_point(nextbar.to_local(mousepos)):
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				Manager.next_level()
