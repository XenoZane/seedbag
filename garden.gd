extends Node2D

const REPEAY_DELAY: float = 0.2
var echo_pressed_delay: float = 0.0

#region MIGHT OR MIGHT NOT USE...
@export var will_trample_pink_seeds: bool = false

var steps_taken: int = 0
const STEPS_TO_THROW: int = 1

enum ObjectType {NOTHING, GREEN_BAG, PINK_BAG, SCYTHE}

# struct
class Player:
	var coords: Vector2i
	var target_coords: Vector2i
	var can_move: bool
	var bag_steps: int # -1 == emptyhanded, integer == number of steps until thrown
	var what_carrying: ObjectType

var green_bag_coords: Array[Vector2i] = []
var pink_bag_coords: Array[Vector2i] = []
var scythe_coords: Array[Vector2i] = []
var players: Array[Player] = []

# NOTE (sam): minimal to get working... it's not a minimal delta as it could be.
# maybe we dont care?
class UndoState:
	var players: Array[Player]
	var green_bag_coords: Array[Vector2i]
	var pink_bag_coords: Array[Vector2i]
	var scythe_coords: Array[Vector2i]
	var green_dirt_seeded_tiles: Array[Vector2i]
	var pink_dirt_seeded_tiles: Array[Vector2i]

var undo_stack: Array[UndoState] = []
var last_move_was_reset: bool = false


const WALL_ATLAS = Vector2i(0, 0)
const WALL_BOUNCE_ATLAS = Vector2i(1, 0)

const PLAYER_ATLAS = Vector2i(0, 1)
const STONE_ATLAS = Vector2i(4, 1)

const GREEN_BAG_ATLAS = Vector2i(0, 2)
const PLAYER_GREEN_BAG_0_ATLAS = Vector2i(2, 2)
const PLAYER_GREEN_BAG_1_ATLAS = Vector2i(1, 2)
const GREEN_DIRT_SEEDED_ATLAS = Vector2i(3, 2)
const GREEN_DIRT_ATLAS = Vector2i(4, 2)

const PINK_BAG_ATLAS = Vector2i(0, 3)
const PLAYER_PINK_BAG_0_ATLAS = Vector2i(2, 3)
const PLAYER_PINK_BAG_1_ATLAS = Vector2i(1, 3)
const PINK_DIRT_SEEDED_ATLAS = Vector2i(3, 3)
const PINK_DIRT_ATLAS = Vector2i(4, 3)

const SCYTHE_ATLAS = Vector2i(0, 4)
const PLAYER_SCYTHE_0_ATLAS = Vector2i(2, 4)
const PLAYER_SCYTHE_1_ATLAS = Vector2i(1, 4)

#endregion

const GRASS_ATLAS = Vector2i(0, 5)
const SOIL_ATLAS = Vector2i(1, 5)
const GREEN_ATLAS = Vector2i(2, 5)
const RED_ATLAS = Vector2i(3, 5)
const PINK_ATLAS = Vector2i(4, 5)
const YELLOW_ATLAS = Vector2i(5, 5)
const BLUE_ATLAS = Vector2i(6, 5)
const WHITE_ATLAS = Vector2i(7, 5)
const BLACK_ATLAS = Vector2i(8, 5)

const GRASS_FIXED_ATLAS = Vector2i(0, 6)
const SOIL_FIXED_ATLAS = Vector2i(1, 6)
const GREEN_FIXED_ATLAS = Vector2i(2, 6)
const RED_FIXED_ATLAS = Vector2i(3, 6)
const PINK_FIXED_ATLAS = Vector2i(4, 6)
const YELLOW_FIXED_ATLAS = Vector2i(5, 6)
const BLUE_FIXED_ATLAS = Vector2i(6, 6)
const WHITE_FIXED_ATLAS = Vector2i(7, 6)
const BLACK_FIXED_ATLAS = Vector2i(8, 6)

var grassable_tiles: Array[Vector2i]
var plantable_tiles: Array[Vector2i]

enum Tool {
	NONE,
	SHOVEL,
	BLACK,
	WHITE,
}
var current_tool: Tool = Tool.NONE
var current_tool_text: String = "tools"

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

func logg(msg: String):
	print("[step %d] %s" % [steps_taken, msg])

func _ready() -> void:
	initial_world_state = world_tiles.tile_map_data
	initial_entity_world_state = entity_tiles.tile_map_data # need to save this for a reset.
	for coords: Vector2i in world_tiles.get_used_cells():
		var atlas := world_tiles.get_cell_atlas_coords(coords)
		if atlas == GRASS_ATLAS:
			grassable_tiles.push_back(coords)
		elif atlas in [SOIL_ATLAS, SOIL_FIXED_ATLAS]:
			world_tiles.set_cell(coords, 0, SOIL_FIXED_ATLAS)
			plantable_tiles.push_back(coords)

func push_undo_state():
	var state = UndoState.new()
	
	for player in players:
		var copy := Player.new()
		copy.coords = player.coords
		copy.target_coords = player.target_coords
		copy.bag_steps = player.bag_steps
		copy.can_move = player.can_move
		copy.what_carrying = player.what_carrying
		state.players.push_back(copy)
	state.green_bag_coords = green_bag_coords.duplicate()
	state.pink_bag_coords = pink_bag_coords.duplicate()
	state.scythe_coords = scythe_coords.duplicate()
	
	# NOTE (sam): any state-changing world tiles can get saved here.
	for coord in world_tiles.get_used_cells():
		var atlas := world_tiles.get_cell_atlas_coords(coord)
		if atlas == GREEN_DIRT_SEEDED_ATLAS:
			state.green_dirt_seeded_tiles.push_back(coord)
		elif atlas == PINK_DIRT_SEEDED_ATLAS:
			state.pink_dirt_seeded_tiles.push_back(coord)
			
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

func undo() -> void:
	assert(false, "undo not implemented for this version...")
	#if len(undo_stack) < 1:
		#return
	#
	#var state: UndoState = undo_stack.pop_back()
	#players.clear()
	#for player in state.players:
		#var copy := Player.new()
		#copy.coords = player.coords
		#copy.target_coords = player.target_coords
		#copy.bag_steps = player.bag_steps
		#copy.can_move = player.can_move
		#copy.what_carrying = player.what_carrying
		#players.push_back(copy)
	#green_bag_coords = state.green_bag_coords.duplicate()
	#pink_bag_coords = state.pink_bag_coords.duplicate()
	#scythe_coords = state.scythe_coords.duplicate()
	#
	## NOTE (sam): any state-changing world tiles can get restored here.
	#world_tiles.tile_map_data = initial_world_state
	#for coords: Vector2i in state.green_dirt_seeded_tiles:
		## check incase of bugs for the moment.
		#var tile := world_tiles.get_cell_atlas_coords(coords)
		#assert(tile == GREEN_DIRT_ATLAS or tile == GREEN_DIRT_SEEDED_ATLAS, "saved green dirt seeded for non-dirt world tile")
		#world_tiles.set_cell(coords, 0, GREEN_DIRT_SEEDED_ATLAS)
	#for coords: Vector2i in state.pink_dirt_seeded_tiles:
		## check incase of bugs for the moment.
		#var tile := world_tiles.get_cell_atlas_coords(coords)
		#assert(tile == PINK_DIRT_ATLAS or tile == PINK_DIRT_SEEDED_ATLAS, "saved pink dirt seeded for non-dirt world tile")
		#world_tiles.set_cell(coords, 0, PINK_DIRT_SEEDED_ATLAS)

func _input(event: InputEvent) -> void:
	if completed:
		return
	
	if event is InputEventMouseMotion:
		var mousepos: Vector2 = get_global_mouse_position() # lol
		
		if $Toolbar/ColorRect.get_rect().has_point($Toolbar.to_local(mousepos)):
			if $Toolbar/Shovel.get_rect().has_point($Toolbar/Shovel.to_local(mousepos)):
				$Toolbar/ToolText.text = "shovel"
				$Indicator.position = $Toolbar/Shovel.global_position
			elif $Toolbar/Black.get_rect().has_point($Toolbar/Black.to_local(mousepos)):
				$Toolbar/ToolText.text = "black x%d" % (black_starting_amount - black_planted)
				$Indicator.position = $Toolbar/Black.global_position
			elif $Toolbar/White.get_rect().has_point($Toolbar/White.to_local(mousepos)):
				$Toolbar/ToolText.text = "white x%d" % (white_starting_amount - white_planted)
				$Indicator.position = $Toolbar/White.global_position
		else:
			$Toolbar/ToolText.text = current_tool_text
			var tilepos = world_tiles.local_to_map(mousepos)
			var tilesize = world_tiles.tile_set.tile_size
			$Indicator.position = tilepos * tilesize + Vector2i.ONE * (tilesize / 2)
			
			var atlas = world_tiles.get_cell_atlas_coords(tilepos)
			
		
	if event is InputEventMouseButton:
		var mousepos: Vector2 = get_global_mouse_position()
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if $Toolbar/ColorRect.get_rect().has_point($Toolbar.to_local(mousepos)):
				if $Toolbar/Shovel.get_rect().has_point($Toolbar/Shovel.to_local(mousepos)):
					current_tool = Tool.SHOVEL
					current_tool_text = "shovel"
				elif $Toolbar/Black.get_rect().has_point($Toolbar/Black.to_local(mousepos)):
					current_tool = Tool.BLACK
					current_tool_text = "black x%d" % (black_starting_amount - black_planted)
				elif $Toolbar/White.get_rect().has_point($Toolbar/White.to_local(mousepos)):
					current_tool = Tool.WHITE
					current_tool_text = "white x%d" % (white_starting_amount - white_planted)
				$Toolbar/ToolText.text = current_tool_text
			else:
				var tilepos = world_tiles.local_to_map(mousepos)
				var atlas = world_tiles.get_cell_atlas_coords(tilepos)
				# rules for acting..
				if current_tool == Tool.SHOVEL:
					if atlas == GRASS_ATLAS:
						world_tiles.set_cell(tilepos, 0, SOIL_ATLAS)
					elif atlas == SOIL_ATLAS:
						world_tiles.set_cell(tilepos, 0, GRASS_ATLAS)
					elif atlas == BLACK_ATLAS:
						if tilepos in grassable_tiles:
							world_tiles.set_cell(tilepos, 0, SOIL_ATLAS)
						elif tilepos in plantable_tiles:
							world_tiles.set_cell(tilepos, 0, SOIL_FIXED_ATLAS)
						black_planted -= 1
					elif atlas == WHITE_ATLAS:
						if tilepos in grassable_tiles:
							world_tiles.set_cell(tilepos, 0, SOIL_ATLAS)
						elif tilepos in plantable_tiles:
							world_tiles.set_cell(tilepos, 0, SOIL_FIXED_ATLAS)
						black_planted -= 1
				elif current_tool == Tool.BLACK:
					if (atlas == SOIL_ATLAS or atlas == SOIL_FIXED_ATLAS or atlas == WHITE_ATLAS) and black_planted < black_starting_amount:
						world_tiles.set_cell(tilepos, 0, BLACK_ATLAS)
						black_planted += 1
						if atlas == WHITE_ATLAS:
							white_planted -= 1
						current_tool_text = "black x%d" % (black_starting_amount - black_planted)
					elif atlas == BLACK_ATLAS:
						if tilepos in grassable_tiles:
							world_tiles.set_cell(tilepos, 0, SOIL_ATLAS)
						elif tilepos in plantable_tiles:
							world_tiles.set_cell(tilepos, 0, SOIL_FIXED_ATLAS)
						black_planted -= 1
						current_tool_text = "black x%d" % (black_starting_amount - black_planted)
				elif current_tool == Tool.WHITE:
					if (atlas == SOIL_ATLAS or atlas == SOIL_FIXED_ATLAS or atlas == BLACK_ATLAS) and white_planted < white_starting_amount:
						world_tiles.set_cell(tilepos, 0, WHITE_ATLAS)
						white_planted += 1
						if atlas == BLACK_ATLAS:
							black_planted -= 1
						current_tool_text = "white x%d" % (white_starting_amount - white_planted)
					elif atlas == WHITE_ATLAS:
						if tilepos in grassable_tiles:
							world_tiles.set_cell(tilepos, 0, SOIL_ATLAS)
						elif tilepos in plantable_tiles:
							world_tiles.set_cell(tilepos, 0, SOIL_FIXED_ATLAS)
						white_planted -= 1
						current_tool_text = "white x%d" % (white_starting_amount - white_planted)

				$Toolbar/ToolText.text = current_tool_text
				
				# check for completion upon making any edit.
				if not completed:
					if black_planted < black_starting_amount or white_planted < white_starting_amount:
						return
					else:
						if all_rules_followed():
							logg("Level complete!")
							$Toolbar/ToolText.text = "complete!"
							completed = true
							complete.emit()

func all_rules_followed() -> bool:
	var found_black_violation := false
	var found_white_violation := false
	const adjacents: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT]
	for coords: Vector2i in world_tiles.get_used_cells():
		var tile := world_tiles.get_cell_atlas_coords(coords)
		if tile == BLACK_ATLAS or tile == BLACK_FIXED_ATLAS:
			# 1. ensure no black flowers adjacent
			for direction in adjacents:
				var adj_neighbor := world_tiles.get_cell_atlas_coords(coords + direction)
				if adj_neighbor in [BLACK_ATLAS, BLACK_FIXED_ATLAS]:
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
				elif atlas in [BLACK_ATLAS, BLACK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			for i in range(coords.x + 1, right_x, 1):
				var atlas := world_tiles.get_cell_atlas_coords(Vector2i(i, coords.y))
				if atlas == WALL_ATLAS:
					break
				elif atlas in [BLACK_ATLAS, BLACK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			for i in range(coords.y - 1, top_y, -1):
				var atlas := world_tiles.get_cell_atlas_coords(Vector2i(coords.x, i))
				if atlas == WALL_ATLAS:
					break
				elif atlas in [BLACK_ATLAS, BLACK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			for i in range(coords.y + 1, bottom_y, 1):
				var atlas := world_tiles.get_cell_atlas_coords(Vector2i(coords.x, i))
				if atlas == WALL_ATLAS:
					break
				elif atlas in [BLACK_ATLAS, BLACK_FIXED_ATLAS]:
					found_any_black_flower = true
					break
			found_black_violation = not found_any_black_flower
			if found_black_violation:
				print("[RULE VIOLATION]: black flower has no black flowers in line of sight.")
				break
		elif tile == WHITE_ATLAS or tile == WHITE_FIXED_ATLAS:
			# 1. ensure 1 above/below and 1 left/right
			var left_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.LEFT)
			var right_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.RIGHT)
			if left_tile in [WHITE_ATLAS, WHITE_FIXED_ATLAS] and right_tile in [WHITE_ATLAS, WHITE_FIXED_ATLAS]:
				found_white_violation = true
				print("[RULE VIOLATION]: white flower is in a horizontal line of 3+ white flowers.")
				break
				
			var up_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.UP)
			var down_tile := world_tiles.get_cell_atlas_coords(coords + Vector2i.DOWN)
			if up_tile in [WHITE_ATLAS, WHITE_FIXED_ATLAS] and down_tile in [WHITE_ATLAS, WHITE_FIXED_ATLAS]:
				found_white_violation = true
				print("[RULE VIOLATION]: white flower is in a vertical line of 3+ white flowers.")
				break
	return not found_black_violation and not found_white_violation

func _process(delta: float) -> void:
	echo_pressed_delay -= delta
