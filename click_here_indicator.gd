extends Sprite2D

var initial_pos: Vector2
const animate_offset: Vector2 = Vector2(0, -2)
var animate_time: float = 0.75
var tween: Tween
var is_offset: bool = false

func _ready() -> void:
	if Manager.has_clicked_tool:
		hide()
	
	initial_pos = position
	tween = create_tween().set_loops()
	tween.tween_interval(animate_time)
	tween.tween_callback(func():
		position = (initial_pos if is_offset else initial_pos + animate_offset)
		is_offset = !is_offset
	)

func _process(_delta: float) -> void:
	if Manager.has_clicked_tool:
		tween.kill()
		queue_free()
