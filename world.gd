extends Node2D

const REPEAY_DELAY: float = 0.2
var echo_pressed_delay: float = 0.0

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

@onready var world_tiles: TileMapLayer = $WorldTiles
@onready var entity_tiles: TileMapLayer = $EntityTiles

var initial_world_state: PackedByteArray
var initial_entity_world_state: PackedByteArray

var completed: bool = false
signal complete

func logg(msg: String):
	print("[step %d] %s" % [steps_taken, msg])

func _ready() -> void:
	initial_world_state = world_tiles.tile_map_data
	initial_entity_world_state = entity_tiles.tile_map_data # need to save this for a reset.
	for coords: Vector2i in entity_tiles.get_used_cells():
		if entity_tiles.get_cell_atlas_coords(coords) == GREEN_BAG_ATLAS:
			green_bag_coords.push_back(coords)
		elif entity_tiles.get_cell_atlas_coords(coords) == PINK_BAG_ATLAS:
			pink_bag_coords.push_back(coords)
		elif entity_tiles.get_cell_atlas_coords(coords) == SCYTHE_ATLAS:
			scythe_coords.push_back(coords)
		elif entity_tiles.get_cell_atlas_coords(coords) == PLAYER_ATLAS:
			var new_player: Player = Player.new()
			new_player.coords = coords
			new_player.bag_steps = -1
			new_player.what_carrying = ObjectType.NOTHING
			players.push_back(new_player)

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
	players.clear()
	green_bag_coords.clear()
	pink_bag_coords.clear()
	scythe_coords.clear()
	world_tiles.tile_map_data = initial_world_state
	entity_tiles.tile_map_data = initial_entity_world_state
	
	for coords: Vector2i in entity_tiles.get_used_cells():
		if entity_tiles.get_cell_atlas_coords(coords) == GREEN_BAG_ATLAS:
			green_bag_coords.push_back(coords)
		elif entity_tiles.get_cell_atlas_coords(coords) == PINK_BAG_ATLAS:
			pink_bag_coords.push_back(coords)
		elif entity_tiles.get_cell_atlas_coords(coords) == SCYTHE_ATLAS:
			scythe_coords.push_back(coords)
		elif entity_tiles.get_cell_atlas_coords(coords) == PLAYER_ATLAS:
			var new_player: Player = Player.new()
			new_player.coords = coords
			new_player.bag_steps = -1
			new_player.what_carrying = ObjectType.NOTHING
			players.push_back(new_player)
	
	last_move_was_reset = true

func undo() -> void:
	if len(undo_stack) < 1:
		return
	
	var state: UndoState = undo_stack.pop_back()
	players.clear()
	for player in state.players:
		var copy := Player.new()
		copy.coords = player.coords
		copy.target_coords = player.target_coords
		copy.bag_steps = player.bag_steps
		copy.can_move = player.can_move
		copy.what_carrying = player.what_carrying
		players.push_back(copy)
	green_bag_coords = state.green_bag_coords.duplicate()
	pink_bag_coords = state.pink_bag_coords.duplicate()
	scythe_coords = state.scythe_coords.duplicate()
	
	# NOTE (sam): any state-changing world tiles can get restored here.
	world_tiles.tile_map_data = initial_world_state
	for coords: Vector2i in state.green_dirt_seeded_tiles:
		# check incase of bugs for the moment.
		var tile := world_tiles.get_cell_atlas_coords(coords)
		assert(tile == GREEN_DIRT_ATLAS or tile == GREEN_DIRT_SEEDED_ATLAS, "saved green dirt seeded for non-dirt world tile")
		world_tiles.set_cell(coords, 0, GREEN_DIRT_SEEDED_ATLAS)
	for coords: Vector2i in state.pink_dirt_seeded_tiles:
		# check incase of bugs for the moment.
		var tile := world_tiles.get_cell_atlas_coords(coords)
		assert(tile == PINK_DIRT_ATLAS or tile == PINK_DIRT_SEEDED_ATLAS, "saved pink dirt seeded for non-dirt world tile")
		world_tiles.set_cell(coords, 0, PINK_DIRT_SEEDED_ATLAS)


func _input(event: InputEvent) -> void:
	if completed:
		return
		
	if event.is_action_pressed("undo"):
		if event.is_echo() and echo_pressed_delay <= 0:
			echo_pressed_delay = REPEAY_DELAY
		elif event.is_echo() and echo_pressed_delay > 0:
			return
		
		undo()
		update_entity_visuals()
		return
	
	var movement_dir: Vector2i = Vector2i.ZERO
	if event.is_action_pressed("reset"):
		# NOTE (sam): nice if we spam reset, we only save a single operation in the undo stack.
		# right now undo state is done before a move (eg. saves the previous right before we do the next)
		# so that we have the state we want to jump back to at the top.
		# if we saved after every move, we'd have to peek back 2, maybe there's a reason to do this (eg. saving and resuming a session from disk).
		if not last_move_was_reset:
			push_undo_state()
		
		reset()
		update_entity_visuals()
	elif event.is_action_pressed("left"):
		movement_dir += Vector2i.LEFT
	elif event.is_action_pressed("right"):
		movement_dir += Vector2i.RIGHT
	elif event.is_action_pressed("up"):
		movement_dir += Vector2i.UP
	elif event.is_action_pressed("down"):
		movement_dir += Vector2i.DOWN
	
	if movement_dir != Vector2i.ZERO:
		last_move_was_reset = false
		
		push_undo_state()
		steps_taken += 1
		
		move_players(movement_dir)
		update_entity_visuals()
	
	# check for completion
	if not completed:
		var found_unplanted_green := false
		var found_unplanted_pink := false
		for coords: Vector2i in world_tiles.get_used_cells():
			var tile := world_tiles.get_cell_atlas_coords(coords)
			if tile == PINK_DIRT_ATLAS:
				found_unplanted_pink = true
			elif tile == GREEN_DIRT_ATLAS:
				found_unplanted_green = true
		if not found_unplanted_green and not found_unplanted_pink:
			logg("Level complete!")
			completed = true
			complete.emit()

func move_players(dir: Vector2i) -> void:
	logg("move players")
	# phase 1: initial intent
	for player: Player in players:
		player.can_move = true
		
		if player.bag_steps == 0:
			# throw
			player.target_coords = player.coords
			player.can_move = false
			player.bag_steps = -1
			throw_item(player.coords, dir, player.what_carrying)
			player.what_carrying = ObjectType.NOTHING
			continue
		
		# else, move
		player.target_coords = player.coords + dir
	
	# phase 2: resolve collisions
	var changed: bool = true
	while changed:
		changed = false
		
		for player: Player in players:
			if !player.can_move:
				continue
			
			# trying to move into a wall
			var world_atlas: Vector2i = world_tiles.get_cell_atlas_coords(player.target_coords)
			if world_atlas == WALL_ATLAS or world_atlas == WALL_BOUNCE_ATLAS or \
				(player.what_carrying != ObjectType.NOTHING and (green_bag_coords.has(player.target_coords) or pink_bag_coords.has(player.target_coords) or scythe_coords.has(player.target_coords))):
				player.can_move = false
				player.target_coords = player.coords
				changed = true
				break
			
			for other: Player in players:
				if player == other:
					continue
				
				# trying to move into someone who is staying
				if player.target_coords == other.coords and !other.can_move:
					player.can_move = false
					player.target_coords = player.coords
					changed = true
					break
				
				# same destination conflict
				if (player.target_coords == other.target_coords and player.target_coords != player.coords):
					player.can_move = false
					player.target_coords = player.coords
					other.can_move = false
					other.target_coords = other.coords
					changed = true
					break

	# phase 3: commit
	for player: Player in players:
		if player.coords != player.target_coords and player.bag_steps >= 0:
			player.bag_steps -= 1
		player.coords = player.target_coords
		# pick up bag
		if player.coords in green_bag_coords:
			player.bag_steps = STEPS_TO_THROW
			player.what_carrying = ObjectType.GREEN_BAG
			green_bag_coords.erase(player.coords)
		elif player.coords in pink_bag_coords:
			player.bag_steps = STEPS_TO_THROW
			player.what_carrying = ObjectType.PINK_BAG
			pink_bag_coords.erase(player.coords)
		elif player.coords in scythe_coords:
			player.bag_steps = STEPS_TO_THROW
			player.what_carrying = ObjectType.SCYTHE
			scythe_coords.erase(player.coords)
		
		# trample
		if will_trample_pink_seeds:
			var tile := world_tiles.get_cell_atlas_coords(player.coords)
			if tile == PINK_DIRT_SEEDED_ATLAS:
				world_tiles.set_cell(player.coords, 0, PINK_DIRT_ATLAS)


func update_entity_visuals() -> void:
	entity_tiles.clear()
	for coords in green_bag_coords:
		entity_tiles.set_cell(coords, 0, GREEN_BAG_ATLAS)
	for coords in pink_bag_coords:
		entity_tiles.set_cell(coords, 0, PINK_BAG_ATLAS)
	for coords in scythe_coords:
		entity_tiles.set_cell(coords, 0, SCYTHE_ATLAS)
	for player in players:
		match player.bag_steps:
			-1:
				entity_tiles.set_cell(player.coords, 0, PLAYER_ATLAS)
			0:
				match player.what_carrying:
					ObjectType.NOTHING:
						entity_tiles.set_cell(player.coords, 0, PLAYER_ATLAS)
					ObjectType.GREEN_BAG:
						entity_tiles.set_cell(player.coords, 0, PLAYER_GREEN_BAG_0_ATLAS)
					ObjectType.PINK_BAG:
						entity_tiles.set_cell(player.coords, 0, PLAYER_PINK_BAG_0_ATLAS)
					ObjectType.SCYTHE:
						entity_tiles.set_cell(player.coords, 0, PLAYER_SCYTHE_0_ATLAS)
			1:
				match player.what_carrying:
					ObjectType.NOTHING:
						entity_tiles.set_cell(player.coords, 0, PLAYER_ATLAS)
					ObjectType.GREEN_BAG:
						entity_tiles.set_cell(player.coords, 0, PLAYER_GREEN_BAG_1_ATLAS)
					ObjectType.PINK_BAG:
						entity_tiles.set_cell(player.coords, 0, PLAYER_PINK_BAG_1_ATLAS)
					ObjectType.SCYTHE:
						entity_tiles.set_cell(player.coords, 0, PLAYER_SCYTHE_1_ATLAS)


func throw_item(from_coords: Vector2i, dir: Vector2i, type: ObjectType) -> void:
	var i: int = 0
	var target_coords: Vector2i
	while(true):
		i += 1
		target_coords = from_coords + dir * i
		update_world_during_throw(target_coords, type)
		var world_atlas = world_tiles.get_cell_atlas_coords(target_coords)
		if scythe_coords.has(target_coords) and (type == ObjectType.GREEN_BAG or type == ObjectType.PINK_BAG):
				return # return without adding back to list AKA kill me
		if world_atlas == WALL_ATLAS or (type != ObjectType.SCYTHE and (pink_bag_coords.has(target_coords) or green_bag_coords.has(target_coords))):
			target_coords = bounce_item(target_coords, -dir, type, 1)
			break
		if world_atlas == WALL_BOUNCE_ATLAS:
			target_coords = bounce_item(target_coords, -dir, type, 2)
			break
			
	
	if type == ObjectType.GREEN_BAG:
		green_bag_coords.push_back(target_coords)
	elif type == ObjectType.PINK_BAG:
		pink_bag_coords.push_back(target_coords)
	elif type == ObjectType.SCYTHE:
		scythe_coords.push_back(target_coords)
	
	# kill any players it lands on
	for player in players:
		if player.coords == target_coords:
			players.erase(player)
			break

func bounce_item(from_coords: Vector2i, dir: Vector2i, type: int, max_dist: int = 9999) -> Vector2i:
	var i: int = 0
	var target_coords: Vector2i = from_coords
	while(i < max_dist):
		i += 1
		target_coords = from_coords + dir * i
		update_world_during_throw(target_coords, type)
		var world_atlas = world_tiles.get_cell_atlas_coords(target_coords)
		if world_atlas == WALL_ATLAS or world_atlas == WALL_BOUNCE_ATLAS:
			target_coords = target_coords - dir
			break
	return target_coords


func update_world_during_throw(at_coords: Vector2i, type: ObjectType) -> void:
	var world_atlas = world_tiles.get_cell_atlas_coords(at_coords)
	if world_atlas == GREEN_DIRT_ATLAS:
		if type == ObjectType.GREEN_BAG:
			world_tiles.set_cell(at_coords, 0, GREEN_DIRT_SEEDED_ATLAS)
	if world_atlas == PINK_DIRT_ATLAS:
		if type == ObjectType.PINK_BAG:
			world_tiles.set_cell(at_coords, 0, PINK_DIRT_SEEDED_ATLAS)
	if type == ObjectType.SCYTHE:
		if world_atlas == GREEN_DIRT_SEEDED_ATLAS:
			world_tiles.set_cell(at_coords, 0, GREEN_DIRT_ATLAS)
		if world_atlas == PINK_DIRT_SEEDED_ATLAS:
			world_tiles.set_cell(at_coords, 0, PINK_DIRT_ATLAS)
		if green_bag_coords.has(at_coords):
			green_bag_coords.erase(at_coords)
		if pink_bag_coords.has(at_coords):
			pink_bag_coords.erase(at_coords)

func _process(delta: float) -> void:
	echo_pressed_delay -= delta
