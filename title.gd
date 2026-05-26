extends Node2D

@onready var no_save_buttons: Node2D = $NoSaveButtons
@onready var has_save_buttons: Node2D = $HasSaveButtons
var has_save: bool = false
var delete_pressed_once: bool = false
@onready var clicktodelete_1: Sprite2D = $HasSaveButtons/Clicktodelete1
@onready var clicktodelete_2: Sprite2D = $HasSaveButtons/Clicktodelete2

var starting := false

func _ready() -> void:
	if FileAccess.file_exists("user://savegame.save"):
		Manager.load_game()
		has_save_buttons.show()
		no_save_buttons.hide()
		has_save = true
	else:
		has_save_buttons.hide()
		no_save_buttons.show()
		has_save = false


func _on_button_mouse_entered() -> void:
	#MusicManager.sfx_hover_button()
	pass

func _on_button_mouse_exited() -> void:
	pass


func _on_play_button_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if starting or has_save:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Manager.new_game()
			starting = true

func _on_resume_button_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if starting or !has_save:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Manager.continue_game()
			starting = true

func _on_delete_1_button_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if starting or !has_save or delete_pressed_once:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			delete_pressed_once = true
			clicktodelete_1.hide()
			clicktodelete_2.show()

func _on_delete_2_button_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if starting or !has_save or !delete_pressed_once:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Manager.delete_game()
			Manager.restart_game()
