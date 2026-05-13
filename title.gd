extends Node2D

var new_game_text := "new game"
var continue_text := "continue"
var selected := 0
var starting := false

func _ready() -> void:
	update_cursor_visuals()
func update_cursor_visuals():
	if selected == 0:
		$NewGame.text = "# %s #" % new_game_text
		$Continue.text = continue_text
	elif selected == 1:
		$NewGame.text = new_game_text
		$Continue.text = "# %s #" % continue_text

func _input(event: InputEvent) -> void:
	if starting:
		return
		
	if event.is_action_pressed("down"):
		selected = posmod(selected + 1, 2)
		update_cursor_visuals()
	elif event.is_action_released("up"):
		selected = posmod(selected - 1, 2)
		update_cursor_visuals()
	elif event.is_action_pressed("action"):
		if selected == 0:
			#$NewGame.text = "###### %s ######" % new_game_text
			Manager.new_game()
		elif selected == 1:
			#$Continue.text = "###### %s ######" % continue_text
			Manager.continue_game()
		starting = true
