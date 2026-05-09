extends Node2D

const STEPS_TO_THROW: int = 1

# struct
class Player:
	var coords: Vector2i
	var target_coords: Vector2i
	var can_move: bool
	var bag_steps: int # -1 == emptyhanded, integer == number of steps until thrown

var bag_coords: Array[Vector2i] = []
var players: Array[Player] = []

const BAG_ATLAS = Vector2i(0, 1)
const PLAYER_ATLAS = Vector2i(1, 1)
const PLAYER_BAG_0_ATLAS = Vector2i(3, 1)
const PLAYER_BAG_1_ATLAS = Vector2i(2, 1)
const DIRT_ATLAS = Vector2i(0, 0)
const DIRT_SEEDED_ATLAS = Vector2i(1, 0)
const STONE_ATLAS = Vector2i(2, 0)
const WALL_ATLAS = Vector2i(3, 0)
const WALL_BOUNCE_ATLAS = Vector2i(4, 0)

@onready var world_tiles: TileMapLayer = $WorldTiles
@onready var entity_tiles: TileMapLayer = $EntityTiles

var initial_world_state: PackedByteArray

func _ready() -> void:
	initial_world_state = world_tiles.tile_map_data
	for coords: Vector2i in entity_tiles.get_used_cells():
		if entity_tiles.get_cell_atlas_coords(coords) == BAG_ATLAS:
			bag_coords.push_back(coords)
		elif entity_tiles.get_cell_atlas_coords(coords) == PLAYER_ATLAS:
			var new_player: Player = Player.new()
			new_player.coords = coords
			new_player.bag_steps = -1
			players.push_back(new_player)

func reset() -> void:
	pass

func undo() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("undo"):
		undo()
		return
	
	var movement_dir: Vector2i = Vector2i.ZERO
	if event.is_action_pressed("reset"):
		reset()
	elif event.is_action_pressed("left"):
		movement_dir += Vector2i.LEFT
	elif event.is_action_pressed("right"):
		movement_dir += Vector2i.RIGHT
	elif event.is_action_pressed("up"):
		movement_dir += Vector2i.UP
	elif event.is_action_pressed("down"):
		movement_dir += Vector2i.DOWN
	
	if movement_dir != Vector2i.ZERO:
		move_players(movement_dir)
		update_entity_visuals()

func move_players(dir: Vector2i) -> void:
	print("move players")
	# phase 1: initial intent
	for player: Player in players:
		player.can_move = true
		
		if player.bag_steps == 0:
			# throw
			player.target_coords = player.coords
			player.can_move = false
			player.bag_steps = -1
			throw_bag(player.coords, dir)
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
			bag_coords.erase(player.coords)



func update_entity_visuals() -> void:
	entity_tiles.clear()
	for coords in bag_coords:
		entity_tiles.set_cell(coords, 0, BAG_ATLAS)
	for player in players:
		match player.bag_steps:
			-1:
				entity_tiles.set_cell(player.coords, 0, PLAYER_ATLAS)
			0:
				entity_tiles.set_cell(player.coords, 0, PLAYER_BAG_0_ATLAS)
			1:
				entity_tiles.set_cell(player.coords, 0, PLAYER_BAG_1_ATLAS)


func throw_bag(from_coords: Vector2i, dir: Vector2i) -> void:
	var i: int = 0
	var target_coords: Vector2i
	while(true):
		i += 1
		target_coords = from_coords + dir * i
		var world_atlas = world_tiles.get_cell_atlas_coords(target_coords)
		if world_atlas == DIRT_ATLAS:
			world_tiles.set_cell(target_coords, 0, DIRT_SEEDED_ATLAS)
		if world_atlas == WALL_ATLAS:
			target_coords = bounce_bag(target_coords, -dir, 1)
			break
		if world_atlas == WALL_BOUNCE_ATLAS:
			target_coords = bounce_bag(target_coords, -dir, 2)
			break
	
	bag_coords.push_back(target_coords)
	
	# kill any players it lands on
	for player in players:
		if player.coords == target_coords:
			players.erase(player)
			break

func bounce_bag(from_coords: Vector2i, dir: Vector2i, max_dist: int = 9999) -> Vector2i:
	var i: int = 0
	var target_coords: Vector2i = from_coords
	while(i < max_dist):
		i += 1
		target_coords = from_coords + dir * i
		var world_atlas = world_tiles.get_cell_atlas_coords(target_coords)
		if world_atlas == DIRT_ATLAS:
			world_tiles.set_cell(target_coords, 0, DIRT_SEEDED_ATLAS)
		if world_atlas == WALL_ATLAS or world_atlas == WALL_BOUNCE_ATLAS:
			target_coords = target_coords - dir
			break
	return target_coords
