extends Node2D

const REPEAY_DELAY: float = 0.2
var echo_pressed_delay: float = 0.0

#region MIGHT OR MIGHT NOT USE...

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
const WALL_ATLAS = Vector2i(0, 0)
const GRASS_ATLAS = Vector2i(0, 6)
const SOIL_ATLAS = Vector2i(1, 6)

const ROSE_ATLAS = Vector2i(4, 5)
const ROSE_FIXED_ATLAS = Vector2i(4, 6)
const SUNFLOWER_ATLAS = Vector2i(5, 5)
const SUNFLOWER_FIXED_ATLAS = Vector2i(5, 6)
const LAVENDER_ATLAS = Vector2i(3, 5)
const LAVENDER_FIXED_ATLAS = Vector2i(3, 6)

var plantable_tiles: Array[Vector2i]

enum Tool {
	NONE = 0,
	ROSE = 1,
	SUNFLOWER = 2,
	LAVENDER = 3,
}
const FLOWER_TOOLS = [Tool.ROSE, Tool.SUNFLOWER, Tool.LAVENDER]
var current_tool: Tool = Tool.NONE
var available_tools: Array[Tool] = []
var available_tool_sprites: Dictionary[int, Sprite2D] = {}
var first_tool_position: Vector2 = Vector2(-4, 43)


const ROSE_TOOL_SPRITE_REGION := Rect2(32, 56, 8, 8)
const SUNFLOWER_TOOL_SPRITE_REGION := Rect2(24, 56, 8, 8)
const LAVENDER_TOOL_SPRITE_REGION := Rect2(40, 56, 8, 8)
const TOOL_SPRITE_REGIONS: Array[Rect2] = [
	Rect2(32, 0, 8, 8),  # invalid tool
	ROSE_TOOL_SPRITE_REGION, 
	SUNFLOWER_TOOL_SPRITE_REGION, 
	LAVENDER_TOOL_SPRITE_REGION,
]

var level_name: String = "garden xxx"

@onready var world_tiles: TileMapLayer = $WorldTiles
@onready var entity_tiles: TileMapLayer = $EntityTiles

@export var starting_amounts: Dictionary[Tool, int] = {
	Tool.ROSE: 1,
	Tool.SUNFLOWER: 1,
	Tool.LAVENDER: 1,
}
var planted_amounts: Dictionary[Tool, int] = {
	Tool.ROSE: 0,
	Tool.SUNFLOWER: 0,
	Tool.LAVENDER: 0,
}
var flower_atlas_to_tool: Dictionary[Vector2i, int] = {
	ROSE_ATLAS: Tool.ROSE,
	ROSE_FIXED_ATLAS: Tool.ROSE,
	SUNFLOWER_ATLAS: Tool.SUNFLOWER,
	SUNFLOWER_FIXED_ATLAS: Tool.SUNFLOWER,
	LAVENDER_ATLAS: Tool.LAVENDER,
	LAVENDER_FIXED_ATLAS: Tool.LAVENDER
}
var flower_tool_to_atlas: Dictionary[int, Vector2i] = {
	Tool.ROSE: ROSE_ATLAS,
	Tool.SUNFLOWER: SUNFLOWER_ATLAS,
	Tool.LAVENDER: LAVENDER_ATLAS,
}

var initial_world_state: PackedByteArray
var initial_entity_world_state: PackedByteArray

var completed: bool = false
signal complete

# nicer names for things.
func is_rose(atlas: Vector2i) -> bool:
	return atlas in [ROSE_ATLAS, ROSE_FIXED_ATLAS]

func is_sunflower(atlas: Vector2i) -> bool:
	return atlas in [SUNFLOWER_ATLAS, SUNFLOWER_FIXED_ATLAS]

func is_lavender(atlas: Vector2i) -> bool:
	return atlas in [LAVENDER_ATLAS, LAVENDER_FIXED_ATLAS]

func is_planted(atlas: Vector2i) -> bool:
	return atlas in [ROSE_ATLAS, SUNFLOWER_ATLAS, LAVENDER_ATLAS]

func is_flower(atlas: Vector2i) -> bool:
	return atlas in [
		LAVENDER_ATLAS,
		LAVENDER_FIXED_ATLAS,
		ROSE_ATLAS,
		ROSE_FIXED_ATLAS,
		SUNFLOWER_ATLAS,
		SUNFLOWER_FIXED_ATLAS
	]

# NOTE: relies on FIXED flowers being 1 below unfixed in tiles.png
# 
func same_flower(atlas1: Vector2i, atlas2: Vector2i) -> bool:
	return is_flower(atlas1) and is_flower(atlas2) and (atlas1 == atlas2 or atlas1 == atlas2 + Vector2i.UP or atlas2 == atlas1 + Vector2i.UP)

func can_plant_flower_on_spot(mine: Vector2i, target: Vector2i) -> bool:
	return target == SOIL_ATLAS or (is_planted(target) and not same_flower(mine, target))

func _ready() -> void:
	initial_world_state = world_tiles.tile_map_data
	initial_entity_world_state = entity_tiles.tile_map_data # need to save this for a reset.
	
	level_name = $Nextbar/LevelText.text
	
	for coords: Vector2i in world_tiles.get_used_cells():
		var atlas := world_tiles.get_cell_atlas_coords(coords)
		if atlas == SOIL_ATLAS:
			plantable_tiles.push_back(coords)
	
	for tool in starting_amounts.keys():
		if starting_amounts[tool] > 0:
			available_tools.append(tool)
	
	# order must be the same as Tool enum: Rose, Sunflower, Lavender, ...
	for idx in available_tools.size():
		var tool := available_tools[idx]
		var spr := Sprite2D.new()
		spr.texture = preload("res://tiles.png")
		spr.region_enabled = true
		spr.region_rect = TOOL_SPRITE_REGIONS[tool]
		
		$Toolbar.add_child(spr)
		
		spr.global_position = first_tool_position + (Vector2.RIGHT * 10 * idx)
		
		available_tool_sprites[tool] = spr
		
	$Indicator.hide()

# FIXME (sam): need to record players properly!!
func push_undo_state():
	var state = UndoState.new()
	
	# NOTE (sam): any state-changing world tiles can get saved here.
	for coord in world_tiles.get_used_cells():
		continue
	
	undo_stack.push_back(state)

# basically similar to the init.
func reset() -> void:
	world_tiles.tile_map_data = initial_world_state
	entity_tiles.tile_map_data = initial_entity_world_state
	
	current_tool = Tool.NONE
	
	for flower in planted_amounts.keys():
		planted_amounts[flower] = 0
	
	last_move_was_reset = true

# FIXME (sam): record players properly!!!
func undo() -> void:
	assert(false, "undo not implemented for this version...")
	if len(undo_stack) < 1:
		return
	
	var state: UndoState = undo_stack.pop_back()

func flowers_left(tool: Tool) -> int:
	return starting_amounts[tool] - planted_amounts[tool]

func tool_text(tool: Tool) -> String:
	if tool == Tool.ROSE:
		return "roses x%d" % flowers_left(tool)
	elif tool == Tool.SUNFLOWER:
		return "sunnys x%d" % flowers_left(tool)
	elif tool == Tool.LAVENDER:
		return "lavens x%d" % flowers_left(tool)
	else:
		return "tools"

func try_plant_flower(flower: Tool, target: Vector2i, tilepos: Vector2i) -> bool:
	var atlas := flower_tool_to_atlas[flower]
	if can_plant_flower_on_spot(atlas, target) and planted_amounts[flower] < starting_amounts[flower]:
		world_tiles.set_cell(tilepos, 0, atlas)
		planted_amounts[flower] += 1
		if target in flower_atlas_to_tool:
			planted_amounts[flower_atlas_to_tool[target]] -= 1
		return true
	elif is_planted(target) and same_flower(atlas, target):
		world_tiles.set_cell(tilepos, 0, SOIL_ATLAS)
		planted_amounts[flower] -= 1
		return true
	else:
		return false

func _input(event: InputEvent) -> void:
	# things to "reset" in the UI, will update if the state calls for it.
	$Nextbar/LevelText.text = level_name
	$Nextbar/Prev.region_rect = Rect2(32, 72, 8, 8)
	$Nextbar/Next.region_rect = Rect2(0, 72, 8, 8)
	
	if event is InputEventMouseMotion:
		$Indicator.hide()
		
		var mousepos: Vector2 = get_global_mouse_position() # lol
		
		if $Toolbar/ColorRect.get_rect().has_point($Toolbar.to_local(mousepos)):
			for tool in available_tools:
				var spr: Sprite2D = available_tool_sprites[tool]
				if spr.get_rect().has_point(spr.to_local(mousepos)):
					$Toolbar/ToolText.text = tool_text(tool)
					$Indicator.show()
					$Indicator.position = spr.global_position
					break
		elif $Nextbar/ColorRect.get_rect().has_point($Nextbar.to_local(mousepos)):
			$Indicator.hide()
			if $Nextbar/Prev.get_rect().has_point($Nextbar/Prev.to_local(mousepos)):
				$Nextbar/LevelText.text = "prev"
				$Nextbar/Prev.region_rect = Rect2(24, 72, 8, 8)
			elif $Nextbar/Next.get_rect().has_point($Nextbar/Next.to_local(mousepos)):
				$Nextbar/LevelText.text = "next"
				$Nextbar/Next.region_rect = Rect2(8, 72, 8, 8)
		else:
			$Toolbar/ToolText.text = tool_text(current_tool)
			var tilepos = world_tiles.local_to_map(mousepos)
			var tilesize = world_tiles.tile_set.tile_size
			$Indicator.position = tilepos * tilesize + Vector2i.ONE * (tilesize / 2)
			
			var atlas = world_tiles.get_cell_atlas_coords(tilepos)
			if atlas == WALL_ATLAS:
				$Indicator.hide()
			else:
				$Indicator.show()

	if event is InputEventMouseButton:
		var mousepos: Vector2 = get_global_mouse_position()
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# clicked in toolbar: try select new tool
			if $Toolbar/ColorRect.get_rect().has_point($Toolbar.to_local(mousepos)):
				for tool in available_tools:
					var spr: Sprite2D = available_tool_sprites[tool]
					if spr.get_rect().has_point(spr.to_local(mousepos)):
						current_tool = tool
						$Indicator.show()
						$Indicator.position = spr.global_position
						break
				$Toolbar/ToolText.text = tool_text(current_tool)
			# clicked in nextbar: try switching levels
			elif $Nextbar/ColorRect.get_rect().has_point($Nextbar.to_local(mousepos)):
				if $Nextbar/Prev.get_rect().has_point($Nextbar/Prev.to_local(mousepos)):
					Manager.prev_level()
				elif $Nextbar/Next.get_rect().has_point($Nextbar/Next.to_local(mousepos)):
					Manager.next_level()
			# clicked in tilemap: try using tools.
			else:
				var tilepos = world_tiles.local_to_map(mousepos)
				var target = world_tiles.get_cell_atlas_coords(tilepos)
				var did_plant := try_plant_flower(current_tool, target, tilepos)
				$Toolbar/ToolText.text = tool_text(current_tool)
				
				# check for completion upon making any edit.
				if did_plant:
					for flower in FLOWER_TOOLS:
						if planted_amounts[flower] < starting_amounts[flower]:
							completed = false
							return
					if all_rules_followed():
						completed = true
						# complete.emit()
					else:
						completed = false

	if completed:
		$Toolbar/ToolText.text = "good job."

func tile_follows_rule(atlas: Vector2i, coords: Vector2i, valid_lavenders: Array[Vector2i]) -> bool:
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
		return false
	
	return true
	
func all_rules_followed() -> bool:
	var valid_lavenders: Array[Vector2i] = []
	for coords: Vector2i in world_tiles.get_used_cells():
		var tile := world_tiles.get_cell_atlas_coords(coords)
		if not tile_follows_rule(tile, coords, valid_lavenders):
			return false
	return true

func _process(delta: float) -> void:
	echo_pressed_delay -= delta
