extends Node2D

var steps_taken: int = 0

const STEPS_TO_THROW: int = 1

# struct
class Player:
	var coords: Vector2i
	var target_coords: Vector2i
	var can_move: bool
	var bag_steps: int # -1 == emptyhanded, integer == number of steps until thrown
	var what_carrying: int

var bag_coords: Array[Vector2i] = []
var scythe_coords: Array[Vector2i] = []
var players: Array[Player] = []

# NOTE (sam): minimal to get working... it's not a minimal delta as it could be.
# maybe we dont care?
class UndoState:
	var players: Array[Player]
	var bag_coords: Array[Vector2i]
	var scythe_coords: Array[Vector2i]
	var dirt_seeded_tiles: Array[Vector2i]

var undo_stack: Array[UndoState] = []
var last_move_was_reset: bool = false

const BAG_ATLAS = Vector2i(0, 1)
const PLAYER_ATLAS = Vector2i(1, 1)
const PLAYER_BAG_0_ATLAS = Vector2i(3, 1)
const PLAYER_BAG_1_ATLAS = Vector2i(2, 1)
const DIRT_ATLAS = Vector2i(0, 0)
const DIRT_SEEDED_ATLAS = Vector2i(1, 0)
const STONE_ATLAS = Vector2i(2, 0)
const WALL_ATLAS = Vector2i(3, 0)
const WALL_BOUNCE_ATLAS = Vector2i(4, 0)

const SCYTHE_ATLAS = Vector2i(0, 2)
const PLAYER_SCYTHE_0_ATLAS = Vector2i(3, 2)
const PLAYER_SCYTHE_1_ATLAS = Vector2i(2, 2)

const CARRY_NOTHING := 0
const CARRY_BAG := 1
const CARRY_SCYTHE := 2

@onready var world_tiles: TileMapLayer = $WorldTiles
@onready var entity_tiles: TileMapLayer = $EntityTiles

var initial_world_state: PackedByteArray
var initial_entity_world_state: PackedByteArray

func logg(msg: String):
	print("[step %d] %s" % [steps_taken, msg])

func _ready() -> void:
	initial_world_state = world_tiles.tile_map_data
	initial_entity_world_state = entity_tiles.tile_map_data # need to save this for a reset.
	for coords: Vector2i in entity_tiles.get_used_cells():
		if entity_tiles.get_cell_atlas_coords(coords) == BAG_ATLAS:
			bag_coords.push_back(coords)
		elif entity_tiles.get_cell_atlas_coords(coords) == SCYTHE_ATLAS:
			scythe_coords.push_back(coords)
		elif entity_tiles.get_cell_atlas_coords(coords) == PLAYER_ATLAS:
			var new_player: Player = Player.new()
			new_player.coords = coords
			new_player.bag_steps = -1
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
	state.bag_coords = bag_coords.duplicate()
	state.scythe_coords = scythe_coords.duplicate()
	
	# NOTE (sam): any state-changing world tiles can get saved here.
	for coord in world_tiles.get_used_cells():
		var atlas := world_tiles.get_cell_atlas_coords(coord)
		if atlas == DIRT_SEEDED_ATLAS:
			state.dirt_seeded_tiles.push_back(coord)
			
	undo_stack.push_back(state)

# basically similar to the init.
func reset() -> void:
	players.clear()
	bag_coords.clear()
	scythe_coords.clear()
	world_tiles.tile_map_data = initial_world_state
	entity_tiles.tile_map_data = initial_entity_world_state
	
	for coords: Vector2i in entity_tiles.get_used_cells():
		if entity_tiles.get_cell_atlas_coords(coords) == BAG_ATLAS:
			bag_coords.push_back(coords)
		elif entity_tiles.get_cell_atlas_coords(coords) == SCYTHE_ATLAS:
			scythe_coords.push_back(coords)
		elif entity_tiles.get_cell_atlas_coords(coords) == PLAYER_ATLAS:
			var new_player: Player = Player.new()
			new_player.coords = coords
			new_player.bag_steps = -1
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
	bag_coords = state.bag_coords.duplicate()
	scythe_coords = state.scythe_coords.duplicate()
	
	# NOTE (sam): any state-changing world tiles can get restored here.
	world_tiles.tile_map_data = initial_world_state
	for coords: Vector2i in state.dirt_seeded_tiles:
		# check incase of bugs for the moment.
		var tile := world_tiles.get_cell_atlas_coords(coords)
		assert(tile == DIRT_ATLAS or tile == DIRT_SEEDED_ATLAS, "saved dirt seeded for non-dirt world tile")
		
		world_tiles.set_cell(coords, 0, DIRT_SEEDED_ATLAS)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("undo"):
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
			player.what_carrying = CARRY_NOTHING
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
			if world_atlas == WALL_ATLAS or world_atlas == WALL_BOUNCE_ATLAS:
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
		if player.coords in bag_coords:
			player.bag_steps = STEPS_TO_THROW
			player.what_carrying = CARRY_BAG
			bag_coords.erase(player.coords)
			
		if player.coords in scythe_coords:
			player.bag_steps = STEPS_TO_THROW
			player.what_carrying = CARRY_SCYTHE
			scythe_coords.erase(player.coords)


func update_entity_visuals() -> void:
	entity_tiles.clear()
	for coords in bag_coords:
		entity_tiles.set_cell(coords, 0, BAG_ATLAS)
	for coords in scythe_coords:
		entity_tiles.set_cell(coords, 0, SCYTHE_ATLAS)
	for player in players:
		match player.bag_steps:
			-1:
				entity_tiles.set_cell(player.coords, 0, PLAYER_ATLAS)
			0:
				if player.what_carrying == CARRY_BAG:
					entity_tiles.set_cell(player.coords, 0, PLAYER_BAG_0_ATLAS)
				elif player.what_carrying == CARRY_SCYTHE:
					entity_tiles.set_cell(player.coords, 0, PLAYER_SCYTHE_0_ATLAS)
			1:
				if player.what_carrying == CARRY_BAG:
					entity_tiles.set_cell(player.coords, 0, PLAYER_BAG_1_ATLAS)
				elif player.what_carrying == CARRY_SCYTHE:
					entity_tiles.set_cell(player.coords, 0, PLAYER_SCYTHE_1_ATLAS)


func throw_item(from_coords: Vector2i, dir: Vector2i, type: int) -> void:
	var i: int = 0
	var target_coords: Vector2i
	while(true):
		i += 1
		target_coords = from_coords + dir * i
		var world_atlas = world_tiles.get_cell_atlas_coords(target_coords)
		if world_atlas == DIRT_ATLAS:
			if type == CARRY_BAG:
				world_tiles.set_cell(target_coords, 0, DIRT_SEEDED_ATLAS)
		if world_atlas == DIRT_SEEDED_ATLAS:
			if type == CARRY_SCYTHE:
				world_tiles.set_cell(target_coords, 0, DIRT_ATLAS)
		if world_atlas == WALL_ATLAS:
			target_coords = bounce_item(target_coords, -dir, type, 1)
			break
		if world_atlas == WALL_BOUNCE_ATLAS:
			target_coords = bounce_item(target_coords, -dir, type, 2)
			break
	
	if type == CARRY_BAG:
		bag_coords.push_back(target_coords)
	elif type == CARRY_SCYTHE:
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
		var world_atlas = world_tiles.get_cell_atlas_coords(target_coords)
		if world_atlas == DIRT_ATLAS:
			if type == CARRY_BAG:
				world_tiles.set_cell(target_coords, 0, DIRT_SEEDED_ATLAS)
		if world_atlas == DIRT_SEEDED_ATLAS:
			if type == CARRY_SCYTHE:
				world_tiles.set_cell(target_coords, 0, DIRT_ATLAS)
		if world_atlas == WALL_ATLAS or world_atlas == WALL_BOUNCE_ATLAS:
			target_coords = target_coords - dir
			break
	return target_coords
