class_name Nextbar extends Node2D

var level_name: String = "name error"

signal save_level_data

# tile atlases for arrows
@onready var level_text: RichTextLabel = $LevelText
@onready var prev_chapter_sprite: Sprite2D = $PrevChapter
@onready var prev_garden_sprite: Sprite2D = $PrevGarden
@onready var next_garden_sprite: Sprite2D = $NextGarden
@onready var next_chapter_sprite: Sprite2D = $NextChapter
const PREV_CHAPTER_RECT = Rect2(48, 72, 8, 8)
const PREV_GARDEN_RECT = Rect2(16, 72, 8, 8)
const NEXT_GARDEN_RECT = Rect2(0, 72, 8, 8)
const NEXT_CHAPTER_RECT = Rect2(32, 72, 8, 8)
const PREV_CHAPTER_HOVER_RECT = Rect2(48+8, 72, 8, 8)
const PREV_GARDEN_HOVER_RECT = Rect2(16+8, 72, 8, 8)
const NEXT_GARDEN_HOVER_RECT = Rect2(0+8, 72, 8, 8)
const NEXT_CHAPTER_HOVER_RECT = Rect2(32+8, 72, 8, 8)

@onready var big_arrow_sprite: Sprite2D = $BigArrow
const BIG_ARROW_RECT = Rect2(48, 0, 16, 16)
const BIG_ARROW_HOVER_RECT = Rect2(48+16, 0, 16, 16)

@onready var bg_rect: ColorRect = $BGRect

func _ready() -> void:
	big_arrow_sprite.hide()

func _input(event: InputEvent) -> void:
	level_text.text = level_name
	prev_chapter_sprite.region_rect = PREV_CHAPTER_RECT
	prev_garden_sprite.region_rect = PREV_GARDEN_RECT
	next_garden_sprite.region_rect = NEXT_GARDEN_RECT
	next_chapter_sprite.region_rect = NEXT_CHAPTER_RECT
	big_arrow_sprite.region_rect = BIG_ARROW_RECT
	
	var mousepos: Vector2 = get_global_mouse_position()
	
	if event is InputEventMouseMotion:
		if bg_rect.get_rect().has_point(self.to_local(mousepos)):
			if prev_chapter_sprite.get_rect().has_point(prev_chapter_sprite.to_local(mousepos)):
				level_text.text = "prev chapter"
				prev_chapter_sprite.region_rect = PREV_CHAPTER_HOVER_RECT
			elif prev_garden_sprite.get_rect().has_point(prev_garden_sprite.to_local(mousepos)):
				level_text.text = "prev garden"
				prev_garden_sprite.region_rect = PREV_GARDEN_HOVER_RECT
			elif next_garden_sprite.get_rect().has_point(next_garden_sprite.to_local(mousepos)):
				level_text.text = "next garden"
				next_garden_sprite.region_rect = NEXT_GARDEN_HOVER_RECT
			elif next_chapter_sprite.get_rect().has_point(next_chapter_sprite.to_local(mousepos)):
				level_text.text = "next chapter"
				next_chapter_sprite.region_rect = NEXT_CHAPTER_HOVER_RECT
		elif big_arrow_sprite.visible and big_arrow_sprite.get_rect().has_point(big_arrow_sprite.to_local(mousepos)):
			level_text.text = "all done?"
			big_arrow_sprite.region_rect = BIG_ARROW_HOVER_RECT
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# clicked in nextbar: try switching levels
			if bg_rect.get_rect().has_point(self.to_local(mousepos)):
				if prev_chapter_sprite.get_rect().has_point(prev_chapter_sprite.to_local(mousepos)):
					save_level_data.emit()
					Manager.prev_chapter()
				elif prev_garden_sprite.get_rect().has_point(prev_garden_sprite.to_local(mousepos)):
					save_level_data.emit()
					Manager.prev_level()
				elif next_garden_sprite.get_rect().has_point(next_garden_sprite.to_local(mousepos)):
					save_level_data.emit()
					Manager.next_level()
				elif next_chapter_sprite.get_rect().has_point(next_chapter_sprite.to_local(mousepos)):
					save_level_data.emit()
					Manager.next_chapter()
			elif big_arrow_sprite.visible and big_arrow_sprite.get_rect().has_point(big_arrow_sprite.to_local(mousepos)):
				save_level_data.emit()
				Manager.next_level()

func set_level_name(new_name: String) -> void:
	level_name = new_name

func show_big_arrow() -> void:
	big_arrow_sprite.show()

func global_point_should_hide_indicator(global_point: Vector2) -> bool:
	if bg_rect.get_rect().has_point(self.to_local(global_point)):
		return true
	elif big_arrow_sprite.visible and big_arrow_sprite.get_rect().has_point(big_arrow_sprite.to_local(global_point)):
		return true
	else:
		return false
