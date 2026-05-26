extends HSlider

@export var bus_name: StringName

func _update_icon_visuals() -> void:
	if value > 0.4:
		$Sprite2D.region_rect.position.x = 32
	elif value > 0.0:
		$Sprite2D.region_rect.position.x = 16
	else:
		$Sprite2D.region_rect.position.x = 0

func _ready() -> void:
	if FileAccess.file_exists("user://savegame.save"):
		value_changed.disconnect(_on_value_changed)
		value = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus_name))
		value_changed.connect(_on_value_changed)
	else:
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus_name), value)
	_update_icon_visuals()

func _process(delta: float) -> void:
	var value_from_bus = AudioServer.get_bus_volume_linear(AudioServer.get_bus_index(bus_name))
	if value_from_bus != value:
		set_value_no_signal(value_from_bus)
		_update_icon_visuals()

func _on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus_name), value)
	_update_icon_visuals()
	if bus_name == "SFX":
		MusicManager.maybe_play_slider_update_sound()


func _on_mouse_entered() -> void:
	MusicManager.sfx_hover_button()


func _on_drag_ended(value_changed: bool) -> void:
	Manager.save_game()
