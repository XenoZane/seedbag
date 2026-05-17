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
