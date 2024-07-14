extends Node2D

signal map_generated(center: Vector2i, tiles: Array[Vector2i])

@export var tilemap: TileMap
@export var steps: int = 20
@export var initial_walkers: int = 4
@export var chance_to_turn: float = 0.8
@export var chance_to_spawn_walker: float = 0.2

var walker_positions: Array[Vector2i] = []
var walker_directions: Array[Vector2i] = []
var walker_remaining_steps: Array[int] = []
var walker_chance_to_spawn: Array[float] = []

var directions = [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]

func create_tilemap(tiles: Array[Vector2i]):
	for tile in tilemap.get_used_cells(0):
		tilemap.set_cell(0, tile, -1)
	
	var x_values = tiles.map(func(x): return x.x)	
	var y_values = tiles.map(func(x): return x.y)
	for x in range(x_values.min() - 1, x_values.max() + 2):
		for y in range(y_values.min() - 1, y_values.max() + 2):
			tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))
			
	for tile in tiles:
		tilemap.set_cell(0, tile, 0, Vector2i(1, 0))
	
func generate_map(center: Vector2i) -> Array[Vector2i]:
	var center_tile = center / tilemap.rendering_quadrant_size
	var map_tiles = [center_tile]
	
	for i in initial_walkers:
		_spawn_walker(center_tile, chance_to_spawn_walker)
		
	while len(walker_positions) > 0:
		var indexes_to_clear = []
		for i in len(walker_positions):
			walker_positions[i] += walker_directions[i]
			map_tiles.append(walker_positions[i])
			
			walker_remaining_steps[i] -= 1
			
			if walker_remaining_steps[i] <= 0:
				indexes_to_clear.append(i)
			else:
				var turn_roll = randf_range(0, 1)
				if turn_roll < chance_to_turn:
					walker_directions[i] = _get_random_direction()
					
				var spawn_roll = randf_range(0, 1)
				if spawn_roll < walker_chance_to_spawn[i]:
					walker_chance_to_spawn[i] /= 2
					_spawn_walker(walker_positions[i], walker_chance_to_spawn[i])
		
		indexes_to_clear.reverse()
		for i in indexes_to_clear:
			walker_positions.remove_at(i)
			walker_directions.remove_at(i)
			walker_remaining_steps.remove_at(i)
			walker_chance_to_spawn.remove_at(i)
			
	var unique: Array[Vector2i] = []

	for item in map_tiles:
		if not unique.has(item):
			unique.append(item)

	map_generated.emit(center, unique)
	create_tilemap(unique)
	return unique
	
func _spawn_walker(initial_position: Vector2i, spawn_chance: float):
	walker_positions.append(initial_position)
	walker_directions.append(_get_random_direction())
	walker_remaining_steps.append(steps)
	walker_chance_to_spawn.append(spawn_chance)

func _get_random_direction() -> Vector2i:
	var direction_index = randi_range(0, len(directions) - 1)
	return directions[direction_index]

func _on_generate_pressed():
	generate_map(get_viewport_rect().get_center())
