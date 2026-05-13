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

const WALL_ATLAS = Vector2i(0, 0)

const RED_ATLAS = Vector2i(3, 5)
const PINK_ATLAS = Vector2i(4, 5)
const YELLOW_ATLAS = Vector2i(5, 5)

const GRASS_FIXED_ATLAS = Vector2i(0, 6)
const SOIL_FIXED_ATLAS = Vector2i(1, 6)
const RED_FIXED_ATLAS = Vector2i(3, 6)
const PINK_FIXED_ATLAS = Vector2i(4, 6)
const YELLOW_FIXED_ATLAS = Vector2i(5, 6)

var grassable_tiles: Array[Vector2i]
var plantable_tiles: Array[Vector2i]

enum Tool {
	NONE = 0,
	SHOVEL = 1,
	BLACK = 2,
	WHITE = 3,
}
var current_tool: Tool = Tool.NONE
var current_tool_text: String = "tools"
var available_tools: Array[Tool] = []
var first_tool_position: Vector2 = Vector2(-4, 43)
var tool_sprites: Array[Sprite2D]

var level_name: String = "garden xxx"

@onready var world_tiles: TileMapLayer = $WorldTiles
@onready var entity_tiles: TileMapLayer = $EntityTiles

@export var black_starting_amount: int = 1
@export var white_starting_amount: int = 1

var black_planted: int = 0
var white_planted: int = 0

var initial_world_state: PackedByteArray
var initial_entity_world_state: PackedByteArray

var completed: bool = false
signal complete

func _ready() -> void:
	initial_world_state = world_tiles.tile_map_data
	initial_entity_world_state = entity_tiles.tile_map_data # need to save this for a reset.
	
	level_name = $Nextbar/LevelText.text
	
	for coords: Vector2i in world_tiles.get_used_cells():
		var atlas := world_tiles.get_cell_atlas_coords(coords)
		if atlas in [SOIL_FIXED_ATLAS]:
			world_tiles.set_cell(coords, 0, SOIL_FIXED_ATLAS)
			plantable_tiles.push_back(coords)
			
	if black_starting_amount > 0:
		available_tools.append(Tool.BLACK)
	if white_starting_amount > 0:
		available_tools.append(Tool.WHITE)
		
	tool_sprites = [$Toolbar/Shovel, $Toolbar/Black, $Toolbar/White]
	
	# silly default, just hide tools far away and remove the ones we dont need.
	for spr in tool_sprites:
		spr.hide()
		spr.global_position = Vector2(999999, 999999)
	
	for idx in available_tools.size():
		var spr: Sprite2D = tool_sprites[available_tools[idx] - 1]
		spr.show()
		spr.global_position = first_tool_position
		spr.global_position.x += 10 * idx
	
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
	current_tool_text = "tools"
	black_planted = 0
	white_planted = 0
	
	last_move_was_reset = true

# FIXME (sam): record players properly!!!
func undo() -> void:
	assert(false, "undo not implemented for this version...")
	if len(undo_stack) < 1:
		return
	
	var state: UndoState = undo_stack.pop_back()
	

func _input(event: InputEvent) -> void:
	# things to "reset" in the UI, will update if the state calls for it.
	$Nextbar/LevelText.text = level_name
	$Nextbar/Prev.region_rect = Rect2(32, 72, 8, 8)
	$Nextbar/Next.region_rect = Rect2(0, 72, 8, 8)
	
	if event is InputEventMouseMotion:
		$Indicator.show()
		
		var mousepos: Vector2 = get_global_mouse_position() # lol
		
		if $Toolbar/ColorRect.get_rect().has_point($Toolbar.to_local(mousepos)):
			$Indicator.show()
			if $Toolbar/Shovel.get_rect().has_point($Toolbar/Shovel.to_local(mousepos)):
				$Toolbar/ToolText.text = "shovel"
				$Indicator.position = $Toolbar/Shovel.global_position
			elif $Toolbar/Black.get_rect().has_point($Toolbar/Black.to_local(mousepos)):
				$Toolbar/ToolText.text = "rose x%d" % (black_starting_amount - black_planted)
				$Indicator.position = $Toolbar/Black.global_position
			elif $Toolbar/White.get_rect().has_point($Toolbar/White.to_local(mousepos)):
				$Toolbar/ToolText.text = "sunnys x%d" % (white_starting_amount - white_planted)
				$Indicator.position = $Toolbar/White.global_position
			else:
				$Indicator.hide()
		elif $Nextbar/ColorRect.get_rect().has_point($Nextbar.to_local(mousepos)):
			$Indicator.hide()
			if $Nextbar/Prev.get_rect().has_point($Nextbar/Prev.to_local(mousepos)):
				$Nextbar/LevelText.text = "prev"
				$Nextbar/Prev.region_rect = Rect2(24, 72, 8, 8)
			elif $Nextbar/Next.get_rect().has_point($Nextbar/Next.to_local(mousepos)):
				$Nextbar/LevelText.text = "next"
				$Nextbar/Next.region_rect = Rect2(8, 72, 8, 8)
		else:
			$Toolbar/ToolText.text = current_tool_text
			var tilepos = world_tiles.local_to_map(mousepos)
			var tilesize = world_tiles.tile_set.tile_size
			$Indicator.position = tilepos * tilesize + Vector2i.ONE * (tilesize / 2)
			
			var atlas = world_tiles.get_cell_atlas_coords(tilepos)
			if atlas == WALL_ATLAS:
				$Indicator.hide()
			else:
				$Indicator.show()

	if event is InputEventMouseButton:
		$Indicator.show()
		
		var mousepos: Vector2 = get_global_mouse_position()
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if $Toolbar/ColorRect.get_rect().has_point($Toolbar.to_local(mousepos)):
				if $Toolbar/Shovel.get_rect().has_point($Toolbar/Shovel.to_local(mousepos)):
					current_tool = Tool.SHOVEL
					current_tool_text = "shovel"
				elif $Toolbar/Black.get_rect().has_point($Toolbar/Black.to_local(mousepos)):
					current_tool = Tool.BLACK
					current_tool_text = "rose x%d" % (black_starting_amount - black_planted)
				elif $Toolbar/White.get_rect().has_point($Toolbar/White.to_local(mousepos)):
					current_tool = Tool.WHITE
					current_tool_text = "sunnys x%d" % (white_starting_amount - white_planted)
				$Toolbar/ToolText.text = current_tool_text
			elif $Nextbar/ColorRect.get_rect().has_point($Nextbar.to_local(mousepos)):
				if $Nextbar/Prev.get_rect().has_point($Nextbar/Prev.to_local(mousepos)):
					Manager.prev_level()
				elif $Nextbar/Next.get_rect().has_point($Nextbar/Next.to_local(mousepos)):
					Manager.next_level()
			else:
				var tilepos = world_tiles.local_to_map(mousepos)
				var atlas = world_tiles.get_cell_atlas_coords(tilepos)
				# rules for acting..
				if current_tool == Tool.SHOVEL:
					return
				elif current_tool == Tool.BLACK:
					if (atlas == SOIL_FIXED_ATLAS or atlas == YELLOW_ATLAS) and black_planted < black_starting_amount:
						world_tiles.set_cell(tilepos, 0, PINK_ATLAS)
						black_planted += 1
						if atlas == YELLOW_ATLAS:
							white_planted -= 1
						current_tool_text = "rose x%d" % (black_starting_amount - black_planted)
					elif atlas == PINK_ATLAS:
						if tilepos in plantable_tiles:
							world_tiles.set_cell(tilepos, 0, SOIL_FIXED_ATLAS)
						black_planted -= 1
						current_tool_text = "rose x%d" % (black_starting_amount - black_planted)
				elif current_tool == Tool.WHITE:
					if (atlas == SOIL_FIXED_ATLAS or atlas == PINK_ATLAS) and white_planted < white_starting_amount:
						world_tiles.set_cell(tilepos, 0, YELLOW_ATLAS)
						white_planted += 1
						if atlas == PINK_ATLAS:
							black_planted -= 1
						current_tool_text = "sunnys x%d" % (white_starting_amount - white_planted)
					elif atlas == YELLOW_ATLAS:
						if tilepos in plantable_tiles:
							world_tiles.set_cell(tilepos, 0, SOIL_FIXED_ATLAS)
						white_planted -= 1
						current_tool_text = "sunnys x%d" % (white_starting_amount - white_planted)
				$Toolbar/ToolText.text = current_tool_text
				
				# check for completion upon making any edit.
				if black_planted < black_starting_amount or white_planted < white_starting_amount:
					completed = false
					return
				else:
					if all_rules_followed():
						completed = true
						# complete.emit()
					else:
						completed = false

	if completed:
		$Toolbar/ToolText.text = "good job."

func is_flower(atlas: Vector2i) -> bool:
	return atlas in [
		RED_ATLAS,
		RED_FIXED_ATLAS,
		PINK_ATLAS,
		PINK_FIXED_ATLAS,
		YELLOW_ATLAS,
		YELLOW_FIXED_ATLAS
	]

func same_flower(atlas1: Vector2i, atlas2: Vector2i) -> bool:
	return is_flower(atlas1) and is_flower(atlas2) and (atlas1 == atlas2 or atlas1 == atlas2 + Vector2i.UP or atlas2 == atlas1 + Vector2i.UP)
	
func all_rules_followed() -> bool:
	var found_black_violation := false
	var found_white_violation := false
	var found_x_violation := false
	
	const adjacents: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]
	
	for coords: Vector2i in world_tiles.get_used_cells():
		var tile := world_tiles.get_cell_atlas_coords(coords)
		if tile == PINK_ATLAS or tile == PINK_FIXED_ATLAS:
			# 1. ensure no black flowers adjacent
			for direction in adjacents:
				var adj_neighbor := world_tiles.get_cell_atlas_coords(coords + direction)
				if adj_neighbor in [PINK_ATLAS, PINK_FIXED_ATLAS]:
					print("[RULE VIOLATION]: black flower has adjacent black flower.")
					found_black_violation = true
					break
			if found_black_violation:
				break
			
			# 2. ensure black exists on horz or vert. axis, unblocked by walls.
			var extents := world_tiles.get_used_rect()
			var left_x: int = extents.position.x
			var right_x: int = extents.end.x
			var top_y: int = extents.position.y
			var bottom_y: int = extents.end.y
			var found_any_black_flower := false
			for i in range(coords.x - 1, left_x, -1):
				var atlas := world_tiles.get_cell_atlas_coords(Vector2i(i, coords.y))
				if atlas == WALL_ATLAS:
					break
				elif atlas in [PINK_ATLAS, PINK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			for i in range(coords.x + 1, right_x, 1):
				var atlas := world_tiles.get_cell_atlas_coords(Vector2i(i, coords.y))
				if atlas == WALL_ATLAS:
					break
				elif atlas in [PINK_ATLAS, PINK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			for i in range(coords.y - 1, top_y, -1):
				var atlas := world_tiles.get_cell_atlas_coords(Vector2i(coords.x, i))
				if atlas == WALL_ATLAS:
					break
				elif atlas in [PINK_ATLAS, PINK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			for i in range(coords.y + 1, bottom_y, 1):
				var atlas := world_tiles.get_cell_atlas_coords(Vector2i(coords.x, i))
				if atlas == WALL_ATLAS:
					break
				elif atlas in [PINK_ATLAS, PINK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			found_black_violation = not found_any_black_flower
			if found_black_violation:
				print("[RULE VIOLATION]: black flower has no black flowers in line of sight.")
				break
		elif tile == YELLOW_ATLAS or tile == YELLOW_FIXED_ATLAS:
			# 1. ensure 1 above/below and 1 left/right
			var found_neighbor := false
			for direction in adjacents:
				var adj_neighbor := world_tiles.get_cell_atlas_coords(coords + direction)
				if adj_neighbor in [YELLOW_ATLAS, YELLOW_FIXED_ATLAS]:
					found_neighbor = true
					break
			if not found_neighbor:
				print("[RULE VIOLATION]: sunflower has no neighbors.")
				found_white_violation = true
				break
			
			var left_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.LEFT)
			var right_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.RIGHT)
			if left_tile in [YELLOW_ATLAS, YELLOW_FIXED_ATLAS] and right_tile in [YELLOW_ATLAS, YELLOW_FIXED_ATLAS]:
				found_white_violation = true
				print("[RULE VIOLATION]: white flower is in a horizontal line of 3+ white flowers.")
				break
				
			var up_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.UP)
			var down_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.DOWN)
			if up_tile in [YELLOW_ATLAS, YELLOW_FIXED_ATLAS] and down_tile in [YELLOW_ATLAS, YELLOW_FIXED_ATLAS]:
				found_white_violation = true
				print("[RULE VIOLATION]: white flower is in a vertical line of 3+ white flowers.")
				break
		elif tile == RED_ATLAS or tile == RED_FIXED_ATLAS:
			# 1. ensure black exists on horz or vert. axis, unblocked by walls.
			var extents := world_tiles.get_used_rect()
			var left_x: int = extents.position.x
			var right_x: int = extents.end.x
			var top_y: int = extents.position.y
			var bottom_y: int = extents.end.y
			var found_any_black_flower := false
			for i in range(coords.x - 1, left_x, -1):
				var atlas := world_tiles.get_cell_atlas_coords(Vector2i(i, coords.y))
				if atlas == WALL_ATLAS:
					break
				elif atlas in [PINK_ATLAS, PINK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			for i in range(coords.x + 1, right_x, 1):
				var atlas := world_tiles.get_cell_atlas_coords(Vector2i(i, coords.y))
				if atlas == WALL_ATLAS:
					break
				elif atlas in [PINK_ATLAS, PINK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			for i in range(coords.y - 1, top_y, -1):
				var atlas := world_tiles.get_cell_atlas_coords(Vector2i(coords.x, i))
				if atlas == WALL_ATLAS:
					break
				elif atlas in [PINK_ATLAS, PINK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			for i in range(coords.y + 1, bottom_y, 1):
				var atlas := world_tiles.get_cell_atlas_coords(Vector2i(coords.x, i))
				if atlas == WALL_ATLAS:
					break
				elif atlas in [PINK_ATLAS, PINK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			found_black_violation = not found_any_black_flower
			if found_black_violation:
				print("[RULE VIOLATION]: black flower has no black flowers in line of sight.")
				break
			var left_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.LEFT)
			var right_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.RIGHT)
			var up_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.UP)
			var down_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.DOWN)
			return same_flower(left_tile, right_tile) or same_flower(up_tile, down_tile)
			
			
	return not found_black_violation and not found_white_violation

func _process(delta: float) -> void:
	echo_pressed_delay -= delta
