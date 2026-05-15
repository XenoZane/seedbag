class_name Garden extends Node2D

@onready var nextbar: Nextbar

const REPEAY_DELAY: float = 0.2
var echo_pressed_delay: float = 0.0

class Player:
	var coords: Vector2i
	var visited: Array[Vector2i]

# NOTE (sam): minimal to get working... it's not a minimal delta as it could be.
# maybe we dont care?
class UndoState:
	var player: Player

var undo_stack: Array[UndoState] = []
var last_move_was_reset: bool = false

# tile atlases for the planting logic.
const INVALID_ATLAS = Vector2i(-1, -1)
const WALL_ATLAS = Vector2i(0, 0)
const GRASS_ATLAS = Vector2i(0, 6)
const SOIL_ATLAS = Vector2i(1, 6)



#region flower data
# things in here need to get updated when you add a new flower.
# you should also make an `is_flower()` function for rule-following.
# you'll have to add a rule yourself, in `tile_follows_rule()`.
# 
# unless specified, order does not matter, and should not be relied upon in code

const ROSE_ATLAS = Vector2i(4, 5)
const ROSE_FIXED_ATLAS = Vector2i(4, 6)
const SUNFLOWER_ATLAS = Vector2i(5, 5)
const SUNFLOWER_FIXED_ATLAS = Vector2i(5, 6)
const LAVENDER_ATLAS = Vector2i(3, 5)
const LAVENDER_FIXED_ATLAS = Vector2i(3, 6)
const GLORY_ATLAS = Vector2i(6, 5)
const GLORY_FIXED_ATLAS = Vector2i(6, 6)
const FLOWER_ATLASES = [
	ROSE_ATLAS,
	ROSE_FIXED_ATLAS,
	SUNFLOWER_ATLAS,
	SUNFLOWER_FIXED_ATLAS,
	LAVENDER_ATLAS,
	LAVENDER_FIXED_ATLAS,
	GLORY_ATLAS,
	GLORY_FIXED_ATLAS,
]
const FLOWER_UNFIXED_ATLASES = [
	ROSE_ATLAS,
	SUNFLOWER_ATLAS,
	LAVENDER_ATLAS,
	GLORY_ATLAS,
]

enum Tool {
	NONE = 0,
	ROSE = 1,
	SUNFLOWER = 2,
	LAVENDER = 3,
	GLORY = 4,
}
const FLOWER_TOOLS = [Tool.ROSE, Tool.SUNFLOWER, Tool.LAVENDER, Tool.GLORY]

const ROSE_TOOL_SPRITE_REGION := Rect2(32, 56, 8, 8)
const SUNFLOWER_TOOL_SPRITE_REGION := Rect2(24, 56, 8, 8)
const LAVENDER_TOOL_SPRITE_REGION := Rect2(40, 56, 8, 8)
const GLORY_TOOL_SPRITE_REGION := Rect2(48, 56, 8, 8)
# WARNING: order MUST be the same as Tool enum: None, Rose, Sunflower, Lavender, ...
const TOOL_SPRITE_REGIONS: Array[Rect2] = [
	Rect2(32, 0, 8, 8),  # invalid tool (None)
	ROSE_TOOL_SPRITE_REGION, 
	SUNFLOWER_TOOL_SPRITE_REGION, 
	LAVENDER_TOOL_SPRITE_REGION,
	GLORY_TOOL_SPRITE_REGION
]

const FLOWER_ATLAS_TO_TOOL: Dictionary[Vector2i, int] = {
	ROSE_ATLAS: Tool.ROSE,
	ROSE_FIXED_ATLAS: Tool.ROSE,
	SUNFLOWER_ATLAS: Tool.SUNFLOWER,
	SUNFLOWER_FIXED_ATLAS: Tool.SUNFLOWER,
	LAVENDER_ATLAS: Tool.LAVENDER,
	LAVENDER_FIXED_ATLAS: Tool.LAVENDER,
	GLORY_ATLAS: Tool.GLORY,
	GLORY_FIXED_ATLAS: Tool.GLORY,
}
const FLOWER_TOOL_TO_ATLAS: Dictionary[int, Vector2i] = {
	Tool.ROSE: ROSE_ATLAS,
	Tool.SUNFLOWER: SUNFLOWER_ATLAS,
	Tool.LAVENDER: LAVENDER_ATLAS,
	Tool.GLORY: GLORY_ATLAS
}
const FLOWER_TOOL_TEXT: Dictionary[Tool, String] = {
	Tool.ROSE: "roses",
	Tool.SUNFLOWER: "sunnies",
	Tool.LAVENDER: "lavendah",
	Tool.GLORY: "glories",
}

@export var starting_amounts: Dictionary[Tool, int] = {
	Tool.ROSE: 1,
	Tool.SUNFLOWER: 1,
	Tool.LAVENDER: 1,
	Tool.GLORY: 0,
}
#endregion

# UI layout stuff
const NEXTBAR_POSITION: Vector2 = Vector2(-128, -96)
const TOOLBAR_POSITION: Vector2 = Vector2(-128, 76)
const FIRST_TOOL_POSITION: Vector2 = Vector2(-8, 86)
const TILEMAP_SCALE: Vector2 = Vector2(2.0, 2.0)

@export var level_name: String = "change me"

# stuff that is initialized dynamically on ready.
var toolbar: Toolbar
var available_tools: Array[Tool] = []
var available_tool_sprites: Dictionary[int, Sprite2D] = {}

var world_tiles: TileMapLayer
var initial_world_state: PackedByteArray

var grid_indicator_sprite: Sprite2D
var tool_indicator_sprite: Sprite2D

# tool/planting related state.
var current_tool: Tool = Tool.NONE
var plantable_tiles: Array[Vector2i]
var planted_amounts: Dictionary[Tool, int]

# TODO: completion state from seedbag, but probably needs an update..
var completed: bool = false
signal complete


#region flower comparisons
func is_rose(atlas: Vector2i) -> bool:
	return atlas in [ROSE_ATLAS, ROSE_FIXED_ATLAS]

func is_sunflower(atlas: Vector2i) -> bool:
	return atlas in [SUNFLOWER_ATLAS, SUNFLOWER_FIXED_ATLAS]

func is_lavender(atlas: Vector2i) -> bool:
	return atlas in [LAVENDER_ATLAS, LAVENDER_FIXED_ATLAS]

func is_glory(atlas: Vector2i) -> bool:
	return atlas in [GLORY_ATLAS, GLORY_FIXED_ATLAS]

func is_planted(atlas: Vector2i) -> bool:
	return atlas in FLOWER_UNFIXED_ATLASES

func is_flower(atlas: Vector2i) -> bool:
	return atlas in FLOWER_ATLASES

# NOTE: relies on FIXED flowers being 1 below unfixed in tiles.png
func same_flower(atlas1: Vector2i, atlas2: Vector2i) -> bool:
	return is_flower(atlas1) and is_flower(atlas2) and (atlas1 == atlas2 or atlas1 == atlas2 + Vector2i.UP or atlas2 == atlas1 + Vector2i.UP)

func can_plant_flower_on_spot(mine: Vector2i, target: Vector2i) -> bool:
	return target == SOIL_ATLAS or (is_planted(target) and not same_flower(mine, target))
#endregion

func _ready() -> void:
	world_tiles = $WorldTiles
	initial_world_state = world_tiles.tile_map_data
	world_tiles.scale = TILEMAP_SCALE
	
	# add grid indicator
	grid_indicator_sprite = preload("res://indicator.tscn").instantiate()
	add_child(grid_indicator_sprite)
	
	# add toolbar
	toolbar = preload("res://toolbar.tscn").instantiate()
	add_child(toolbar)
	toolbar.global_position = TOOLBAR_POSITION
	
	# add tool indicator
	tool_indicator_sprite = preload("res://indicator.tscn").instantiate()
	add_child(tool_indicator_sprite)
	
	# add nextbar
	nextbar = preload("res://nextbar.tscn").instantiate()
	nextbar.set_level_name(level_name)
	nextbar.save_level_data.connect(save_level_data)
	add_child(nextbar)
	nextbar.global_position = NEXTBAR_POSITION
	
	for coords: Vector2i in world_tiles.get_used_cells():
		var atlas := world_tiles.get_cell_atlas_coords(coords)
		if atlas == SOIL_ATLAS:
			plantable_tiles.push_back(coords)
	
	for tool in starting_amounts.keys():
		if starting_amounts[tool] > 0:
			available_tools.append(tool)
		planted_amounts[tool] = 0
	
	for idx in available_tools.size():
		var tool := available_tools[idx]
		var spr := Sprite2D.new()
		spr.texture = preload("res://tiles.png")
		spr.region_enabled = true
		spr.region_rect = TOOL_SPRITE_REGIONS[tool]
		toolbar.add_child(spr)
		spr.global_position = FIRST_TOOL_POSITION + (Vector2.RIGHT * 40 * idx)
		
		
		var label_global_pos: Vector2 = FIRST_TOOL_POSITION + (Vector2.RIGHT * (40 * idx + 10)) + (Vector2.UP * 14)
		var amount: int = starting_amounts[tool]
		toolbar.add_amount_label(label_global_pos, amount, tool)
		
		
		available_tool_sprites[tool] = spr

	# load level data
	var level_data: Manager.LevelData = Manager.load_level(scene_file_path)
	if level_data != null:
		world_tiles.tile_map_data = level_data.tiles
		current_tool = level_data.current_tool
		planted_amounts = level_data.current_inventory.duplicate()
	
	grid_indicator_sprite.hide()
	tool_indicator_sprite.hide()

#region undo + reset
# FIXME (sam): need to record players properly!!
func push_undo_state():
	var state = UndoState.new()
	
	# NOTE (sam): any state-changing world tiles can get saved here.
	for coord in world_tiles.get_used_cells():
		continue
	
	undo_stack.push_back(state)

# FIXME (sam): record players properly!!!
func undo() -> void:
	assert(false, "undo not implemented for this version...")
	if len(undo_stack) < 1:
		return
	
	var _state: UndoState = undo_stack.pop_back()

# basically similar to the init.
func reset() -> void:
	world_tiles.tile_map_data = initial_world_state
	
	current_tool = Tool.NONE
	
	for flower in planted_amounts.keys():
		planted_amounts[flower] = 0
	
	last_move_was_reset = true
#endregion

# TODO (sam): i just duplicated all rules followed, probably not needed, being lazy.
func save_level_data() -> void:
	Manager.save_level(world_tiles.tile_map_data, level_name, current_tool, planted_amounts.duplicate(), all_flowers_planted(), all_flowers_planted() and all_rules_followed())

func tool_text(tool: Tool) -> String:
	if tool in FLOWER_TOOLS:
		#return "%s x%d" % [FLOWER_TOOL_TEXT[tool], starting_amounts[tool] - planted_amounts[tool]]
		return FLOWER_TOOL_TEXT[tool]
	else:
		return "seeds"

func update_toolbar_amounts() -> void:
	for tool in available_tools:
		toolbar.amount_labels[tool].text = str(starting_amounts[tool] - planted_amounts[tool])

# TODO: might become "try_use_tool"...
func try_plant_flower(flower: Tool, target: Vector2i, tilepos: Vector2i) -> bool:
	if flower not in FLOWER_TOOLS:
		return false
	
	var atlas := FLOWER_TOOL_TO_ATLAS[flower]
	if can_plant_flower_on_spot(atlas, target) and planted_amounts[flower] < starting_amounts[flower]:
		world_tiles.set_cell(tilepos, 0, atlas)
		planted_amounts[flower] += 1
		if target in FLOWER_ATLAS_TO_TOOL:
			planted_amounts[FLOWER_ATLAS_TO_TOOL[target]] -= 1
		return true
	elif is_planted(target) and same_flower(atlas, target):
		world_tiles.set_cell(tilepos, 0, SOIL_ATLAS)
		planted_amounts[flower] -= 1
		return true
	else:
		return false

func _input(event: InputEvent) -> void:
	# things to "reset" in the UI, will update if the state calls for it.
	
	if event is InputEventMouseMotion:
		grid_indicator_sprite.hide()
		if current_tool == Tool.NONE:
			tool_indicator_sprite.hide()
		
		var mousepos: Vector2 = get_global_mouse_position() # lol
		
		if toolbar.contains_mouse(mousepos):
			for tool in available_tools:
				var spr: Sprite2D = available_tool_sprites[tool]
				if spr.get_rect().has_point(spr.to_local(mousepos)):
					toolbar.set_tool_text(tool_text(tool))
					tool_indicator_sprite.show()
					tool_indicator_sprite.global_position = spr.global_position
					break
		elif nextbar.global_point_should_hide_indicator(mousepos):
			grid_indicator_sprite.hide()
		else:
			toolbar.set_tool_text(tool_text(current_tool))
			var tilepos = world_tiles.local_to_map(world_tiles.to_local(mousepos))
			var tilesize = world_tiles.tile_set.tile_size * Vector2i(world_tiles.scale)
			grid_indicator_sprite.position = tilepos * tilesize + Vector2i.ONE * (tilesize / 2)
			
			var atlas = world_tiles.get_cell_atlas_coords(tilepos)
			if atlas == WALL_ATLAS:
				grid_indicator_sprite.hide()
			else:
				grid_indicator_sprite.show()
	
	if event is InputEventMouseButton:
		var mousepos: Vector2 = get_global_mouse_position()
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# clicked in toolbar: try select new tool
			if toolbar.contains_mouse(mousepos):
				for tool in available_tools:
					var spr: Sprite2D = available_tool_sprites[tool]
					if spr.get_rect().has_point(spr.to_local(mousepos)):
						current_tool = tool
						tool_indicator_sprite.show()
						tool_indicator_sprite.position = spr.global_position
						break
				save_level_data()
				toolbar.set_tool_text(tool_text(current_tool))
			# clicked in tilemap: try using tools.
			else:
				var tilepos = world_tiles.local_to_map(world_tiles.to_local(mousepos))
				var target = world_tiles.get_cell_atlas_coords(tilepos)
				var did_plant := try_plant_flower(current_tool, target, tilepos)
				toolbar.set_tool_text(tool_text(current_tool))
				
				# check for completion upon making any edit.
				if did_plant:
					if all_flowers_planted() and all_rules_followed():
						completed = true
					else:
						completed = false
					
					update_toolbar_amounts()
					save_level_data()


func _process(delta: float) -> void:
	echo_pressed_delay -= delta
	
	if all_flowers_planted():
		nextbar.show_big_arrow()
	else:
		nextbar.hide_big_arrow()


#region rules
func tile_follows_rule(atlas: Vector2i, coords: Vector2i) -> bool:
	if atlas in FLOWER_ATLASES:
		assert(
			is_rose(atlas) or is_sunflower(atlas) or is_lavender(atlas) or is_glory(atlas), 
			"You made a new flower but didn't add a rule for it. Update tile_follows_rule() in garden.gd (and probably create is_flower()))"
		)
	
	const adjacents: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]
	
	if is_rose(atlas):
		# 1. ensure no roses are adjacent
		for direction in adjacents:
			var adj_neighbor := world_tiles.get_cell_atlas_coords(coords + direction)
			if is_rose(adj_neighbor):
				print("[RULE VIOLATION]: rose has adjacent rose.")
				return false
			
		# 2. ensure rose exists on horz or vert. axis, unblocked by walls.
		var extents := world_tiles.get_used_rect()
		var left_check = [coords.x - 1, extents.position.x, -1, true]
		var right_check = [coords.x + 1, extents.end.x, 1, true]
		var top_check = [coords.y - 1, extents.position.y, -1, false]
		var bottom_check = [coords.y + 1, extents.end.y, 1, false]
		var found_any_rose := false
		for linecheck in [left_check, right_check, top_check, bottom_check]:
			var linestart: int = linecheck[0]
			var lineend: int = linecheck[1]
			var iteration_dir: int = linecheck[2]
			var horz: bool = linecheck[3]
			for i in range(linestart, lineend, iteration_dir):
				var offset := Vector2i(i, coords.y) if horz else Vector2i(coords.x, i)
				var other := world_tiles.get_cell_atlas_coords(offset)
				if other == WALL_ATLAS:
					break
				elif is_rose(other):
					found_any_rose = true
					break
		if not found_any_rose:
			print("[RULE VIOLATION]: rose has no roses in line of sight.")
			return false

	elif is_sunflower(atlas):
		# 1. ensure exactly 1 above/below and exactly 1 left/right
		var left_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.LEFT)
		var right_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.RIGHT)
		if is_sunflower(left_tile) and is_sunflower(right_tile):
			print("[RULE VIOLATION]: white flower is in a horizontal line of 3+ white flowers.")
			return false
			
		var up_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.UP)
		var down_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.DOWN)
		if is_sunflower(up_tile) and is_sunflower(down_tile):
			print("[RULE VIOLATION]: white flower is in a vertical line of 3+ white flowers.")
			return false
		
		if not is_sunflower(up_tile) \
			and not is_sunflower(down_tile) \
			and not is_sunflower(left_tile) \
			and not is_sunflower(right_tile):
			print("[RULE VIOLATION]: sunflower has no neighbors.")
			return false

	elif is_lavender(atlas):
		var horz_line := find_lavender_line(coords, Vector2i.RIGHT)
		if check_lavender_line(coords, horz_line):
			return true
		
		var vert_line := find_lavender_line(coords, Vector2i.DOWN)
		if check_lavender_line(coords, vert_line):
			return true
		
		print("[RULE VIOLATION]: lavender is not an interior point in a valid line.")
		return false
	
	elif is_glory(atlas):
		var found_soil: bool = false
		var found_flower: bool = false
		
		for check_atlas in [
			world_tiles.get_cell_atlas_coords(coords + Vector2i.LEFT),
			world_tiles.get_cell_atlas_coords(coords + Vector2i.RIGHT),
			world_tiles.get_cell_atlas_coords(coords + Vector2i.UP),
			world_tiles.get_cell_atlas_coords(coords + Vector2i.DOWN),
		]:
			if is_flower(check_atlas): found_flower = true
			if check_atlas == SOIL_ATLAS: found_soil = true
		
		return found_soil and found_flower
	
	return true

func find_lavender_line(start: Vector2i, direction: Vector2i) -> Array[Vector2i]:
	var line: Array[Vector2i] = [start]
	
	# check positive direction.
	var offset := start + direction
	while world_tiles.get_used_rect().has_point(offset):
		var tile := world_tiles.get_cell_atlas_coords(offset)
		if is_flower(tile):
			line.push_back(offset)
			if not is_lavender(tile):
				break
		else:
			break
		offset += direction
	
	# check negative direction.
	offset = start - direction
	while world_tiles.get_used_rect().has_point(offset):
		var tile := world_tiles.get_cell_atlas_coords(offset)
		if is_flower(tile):
			line.push_front(offset)
			if not is_lavender(tile):
				break
		else:
			break
		offset -= direction
	
	return line

func check_lavender_line(coords: Vector2i, line: Array[Vector2i]) -> bool:
	return (
		line.size() >= 3
		and coords != line[0]
		and coords != line[-1]
		and same_flower(
			world_tiles.get_cell_atlas_coords(line[0]), 
			world_tiles.get_cell_atlas_coords(line[-1])
		) 
		and line.slice(1, -1).all(
			func (p: Vector2i): return is_lavender(world_tiles.get_cell_atlas_coords(p))
		)
	)

func all_flowers_planted() -> bool:
	for flower in starting_amounts:
		if planted_amounts[flower] < starting_amounts[flower]:
			return false
	return true

func all_rules_followed() -> bool:
	for coords: Vector2i in world_tiles.get_used_cells():
		var tile := world_tiles.get_cell_atlas_coords(coords)
		if not tile_follows_rule(tile, coords):
			return false
	return true
#endregion
