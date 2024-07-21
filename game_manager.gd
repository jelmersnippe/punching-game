extends Node2D

signal player_spawned(player: Node2D)
signal wave_changed(wave: int)

var player_scene = preload("res://player.tscn")
var charger_scene = preload("res://enemy/charger.tscn")
var ranged_scene = preload("res://enemy/ranged.tscn")
var big_scene = preload("res://enemy/big.tscn")
var fodder_scene = preload("res://enemy/fodder.tscn")

@export var tile_map: TileMap
@export var spawn_container: Node
@export var enemy_spawn_count: int = 10

var wave_index: int = 0:
	set(value):
		wave_index = value
		wave_changed.emit(wave_index)

var remaining_enemies = 0

var center_tile: Vector2
var top_left_tile: Vector2
var bottom_right_tile: Vector2

func _ready():
	var tiles = tile_map.get_used_cells(0)
	var x_positions = tiles.map(func(x): return x.x)
	var y_positions = tiles.map(func(x): return x.y)
	center_tile = Vector2(round(x_positions.max() / 2), round(y_positions.max() / 2))
	top_left_tile = Vector2(x_positions.min(), y_positions.min())
	bottom_right_tile = Vector2(x_positions.max(), y_positions.max())

func _spawn_enemies():
	if remaining_enemies > 0:
		return
	var enemy_spawns: Array[Vector2i] = []
	
	var tiles = tile_map.get_used_cells(0)
	
	while len(enemy_spawns) < enemy_spawn_count:
		var pos = tiles.pick_random()
		if pos in enemy_spawns or Vector2(pos).distance_to(center_tile) < 5 or pos.x == top_left_tile.x or pos.x == bottom_right_tile.x or pos.y == top_left_tile.y or pos.y == bottom_right_tile.y:
			continue
		
		enemy_spawns.append(pos)
		
	for pos in enemy_spawns:
		var rng = randi_range(0, 100)
		var new: Enemy
		if rng < 40:
			new = charger_scene.instantiate() as Enemy
		elif rng < 60:
			new = ranged_scene.instantiate() as Enemy
		elif rng < 90:
			new = fodder_scene.instantiate() as Enemy
		else:
			new = big_scene.instantiate() as Enemy
			
		new.position = pos * $TileMap.rendering_quadrant_size
		new.health_component.died.connect(_reduce_remaining_enemies)
		spawn_container.add_child.call_deferred(new)
		remaining_enemies += 1
		
	wave_index += 1
	
var player: Player
func _on_ui_start_game_requested():
	for child in spawn_container.get_children():
		child.queue_free()
	remaining_enemies = 0
		
	player = player_scene.instantiate() as Player
	player.position = center_tile * tile_map.rendering_quadrant_size
	player.health_component.died.connect($UI.show_game_over)
	spawn_container.add_child.call_deferred(player)
	player_spawned.emit(player)
	
	wave_changed.connect(func(x): player.health_component.take_damage(-player.health_component.max_health))
	wave_index = 0
	
	_spawn_enemies()
	
func _reduce_remaining_enemies():
	remaining_enemies -= 1
	
	if remaining_enemies <= 0:
		_spawn_enemies()
