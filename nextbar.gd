class_name Nextbar extends Node2D

var level_name: String = "name error"

signal save_level_data

var last_hover_mousepos: Vector2

# tile atlases for arrows
@onready var level_text: RichTextLabel = $LevelText
@onready var prev_chapter_sprite: Sprite2D = $PrevChapter
@onready var prev_garden_sprite: Sprite2D = $PrevGarden
@onready var next_garden_sprite: Sprite2D = $NextGarden
@onready var next_chapter_sprite: Sprite2D = $NextChapter
@onready var prev_chapter_click_area: Polygon2D = $PrevChapter/ClickArea
@onready var prev_garden_click_area: Polygon2D = $PrevGarden/ClickArea
@onready var next_garden_click_area: Polygon2D = $NextGarden/ClickArea
@onready var next_chapter_click_area: Polygon2D = $NextChapter/ClickArea
const PREV_CHAPTER_RECT = Rect2(48, 72, 8, 8)
const PREV_GARDEN_RECT = Rect2(16, 72, 8, 8)
const NEXT_GARDEN_RECT = Rect2(0, 72, 8, 8)
const NEXT_CHAPTER_RECT = Rect2(32, 72, 8, 8)
const PREV_CHAPTER_HOVER_RECT = Rect2(48+8, 72, 8, 8)
const PREV_GARDEN_HOVER_RECT = Rect2(16+8, 72, 8, 8)
const NEXT_GARDEN_HOVER_RECT = Rect2(0+8, 72, 8, 8)
const NEXT_CHAPTER_HOVER_RECT = Rect2(32+8, 72, 8, 8)

@onready var big_arrow_sprite: Sprite2D = $BigArrow
@onready var big_arrow_click_area: Polygon2D = $BigArrow/ClickArea
const BIG_ARROW_RECT = Rect2(48, 0, 16, 16)
const BIG_ARROW_HOVER_RECT = Rect2(48+16, 0, 16, 16)

var prev_garden_hovered_from_entrance: bool = false
var next_garden_hovered_from_entrance: bool = false
var prev_chapter_hovered_from_entrance: bool = false
var next_chapter_hovered_from_entrance: bool = false

@onready var bg_rect: ColorRect = $BGRect

func _ready() -> void:
	big_arrow_sprite.hide()
	
	if Manager.on_last_chapter():
		next_chapter_sprite.hide()
	if Manager.on_last_level():
		next_garden_sprite.hide()

func _input(event: InputEvent) -> void:
	var mousepos: Vector2 = get_global_mouse_position()
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# clicked in nextbar: try switching levels
			if bg_rect.get_rect().has_point(self.to_local(mousepos)):
				if prev_chapter_sprite.visible and Geometry2D.is_point_in_polygon(prev_chapter_click_area.to_local(mousepos), prev_chapter_click_area.polygon):
					save_level_data.emit()
					Manager.prev_chapter()
				elif prev_garden_sprite.visible and Geometry2D.is_point_in_polygon(prev_garden_click_area.to_local(mousepos), prev_garden_click_area.polygon):
					save_level_data.emit()
					Manager.prev_level()
				elif next_garden_sprite.visible and Geometry2D.is_point_in_polygon(next_garden_click_area.to_local(mousepos), next_garden_click_area.polygon):
					save_level_data.emit()
					Manager.next_level()
				elif next_chapter_sprite.visible and Geometry2D.is_point_in_polygon(next_chapter_click_area.to_local(mousepos), next_chapter_click_area.polygon):
					save_level_data.emit()
					Manager.next_chapter()
			elif big_arrow_sprite.visible and Geometry2D.is_point_in_polygon(big_arrow_click_area.to_local(mousepos), big_arrow_click_area.polygon):
				save_level_data.emit()
				Manager.next_level()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("left"):
		Manager.prev_level()
	if Input.is_action_just_pressed("right"):
		Manager.next_level()

func update_hover_visuals(on_entry: bool = false) -> void:
	prev_chapter_sprite.region_rect = PREV_CHAPTER_RECT
	prev_garden_sprite.region_rect = PREV_GARDEN_RECT
	next_garden_sprite.region_rect = NEXT_GARDEN_RECT
	next_chapter_sprite.region_rect = NEXT_CHAPTER_RECT
	big_arrow_sprite.region_rect = BIG_ARROW_RECT
	var mousepos: Vector2 = get_global_mouse_position()
	
	var prev_chapter_hovered := prev_chapter_sprite.visible and Geometry2D.is_point_in_polygon(prev_chapter_click_area.to_local(mousepos), prev_chapter_click_area.polygon)
	var prev_garden_hovered := prev_garden_sprite.visible and Geometry2D.is_point_in_polygon(prev_garden_click_area.to_local(mousepos), prev_garden_click_area.polygon)
	var next_garden_hovered := next_garden_sprite.visible and Geometry2D.is_point_in_polygon(next_garden_click_area.to_local(mousepos), next_garden_click_area.polygon)
	var next_chapter_hovered := next_chapter_sprite.visible and Geometry2D.is_point_in_polygon(next_chapter_click_area.to_local(mousepos), next_chapter_click_area.polygon)
	var big_arrow_hovered := big_arrow_sprite.visible and Geometry2D.is_point_in_polygon(big_arrow_click_area.to_local(mousepos), big_arrow_click_area.polygon)
	var prev_chapter_last_hovered := prev_chapter_sprite.visible and Geometry2D.is_point_in_polygon(prev_chapter_click_area.to_local(last_hover_mousepos), prev_chapter_click_area.polygon)
	var prev_garden_last_hovered := prev_garden_sprite.visible and Geometry2D.is_point_in_polygon(prev_garden_click_area.to_local(last_hover_mousepos), prev_garden_click_area.polygon)
	var next_garden_last_hovered := next_garden_sprite.visible and Geometry2D.is_point_in_polygon(next_garden_click_area.to_local(last_hover_mousepos), next_garden_click_area.polygon)
	var next_chapter_last_hovered := next_chapter_sprite.visible and Geometry2D.is_point_in_polygon(next_chapter_click_area.to_local(last_hover_mousepos), next_chapter_click_area.polygon)
	var big_arrow_last_hovered := big_arrow_sprite.visible and Geometry2D.is_point_in_polygon(big_arrow_click_area.to_local(last_hover_mousepos), big_arrow_click_area.polygon)

	
	if on_entry:
		prev_chapter_hovered_from_entrance = prev_chapter_hovered
		prev_garden_hovered_from_entrance = prev_garden_hovered
		next_garden_hovered_from_entrance = next_garden_hovered
		next_chapter_hovered_from_entrance = next_chapter_hovered
	else:
		if prev_chapter_hovered_from_entrance and not prev_chapter_hovered:
			prev_chapter_hovered_from_entrance = false
		if prev_garden_hovered_from_entrance and not prev_garden_hovered:
			prev_garden_hovered_from_entrance = false
		if next_garden_hovered_from_entrance and not next_garden_hovered:
			next_garden_hovered_from_entrance = false
		if next_chapter_hovered_from_entrance and not next_chapter_hovered:
			next_chapter_hovered_from_entrance = false
	
	if prev_chapter_hovered:
		level_text.text = "prev chapter" if not prev_chapter_hovered_from_entrance else level_name
		prev_chapter_sprite.region_rect = PREV_CHAPTER_HOVER_RECT
		if !prev_chapter_last_hovered and not prev_chapter_hovered_from_entrance: MusicManager.sfx_hover_button()
	elif prev_garden_hovered:
		level_text.text = "prev garden" if not prev_garden_hovered_from_entrance else level_name
		prev_garden_sprite.region_rect = PREV_GARDEN_HOVER_RECT
		if !prev_garden_last_hovered and not prev_garden_hovered_from_entrance: MusicManager.sfx_hover_button()
	elif next_garden_hovered:
		level_text.text = "next garden" if not next_garden_hovered_from_entrance else level_name
		next_garden_sprite.region_rect = NEXT_GARDEN_HOVER_RECT
		if !next_garden_last_hovered and not next_garden_hovered_from_entrance: MusicManager.sfx_hover_button()
	elif next_chapter_hovered:
		level_text.text = "next chapter" if not next_chapter_hovered_from_entrance else level_name
		next_chapter_sprite.region_rect = NEXT_CHAPTER_HOVER_RECT
		if !next_chapter_last_hovered and not next_chapter_hovered_from_entrance: MusicManager.sfx_hover_button()
	elif big_arrow_hovered:
		level_text.text = "all done?"
		big_arrow_sprite.region_rect = BIG_ARROW_HOVER_RECT
		if !big_arrow_last_hovered: MusicManager.sfx_hover_button()
	else:
		level_text.text = level_name
	
	last_hover_mousepos = mousepos

func set_level_name(new_name: String) -> void:
	level_name = new_name

func show_big_arrow() -> void:
	big_arrow_sprite.show()

func hide_big_arrow() -> void:
	big_arrow_sprite.hide()

func global_point_should_hide_indicator(global_point: Vector2) -> bool:
	if bg_rect.get_rect().has_point(self.to_local(global_point)):
		return true
	elif big_arrow_sprite.visible and big_arrow_sprite.get_rect().has_point(big_arrow_sprite.to_local(global_point)):
		return true
	else:
		return false
