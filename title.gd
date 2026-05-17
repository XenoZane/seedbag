extends Node2D

var starting := false

func _input(event: InputEvent) -> void:
	if starting:
		return
	
	# TODO (sam): maybe restore continues?
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if $NewGame.get_rect().has_point(get_global_mouse_position()):
				Manager.new_game()
				starting = true
