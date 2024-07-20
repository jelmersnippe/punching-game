extends Node2D

signal player_spawned(player: Node2D)

var player_scene = preload("res://player.tscn")
var charger_scene = preload("res://enemy/charger.tscn")
var ranged_scene = preload("res://enemy/ranged.tscn")
var big_scene = preload("res://enemy/big.tscn")
var fodder_scene = preload("res://enemy/fodder.tscn")

@export var tile_map: TileMap
@export var spawn_container: Node
@export var enemy_spawn_count: int = 10

var center_tile: Vector2

func _ready():
	var tiles = tile_map.get_used_cells(0)
	var x_positions = tiles.map(func(x): return x.x)
	var y_positions = tiles.map(func(x): return x.y)
	center_tile = Vector2(round(x_positions.max() / 2), round(y_positions.max() / 2))

func _spawn_enemies():
	var enemy_spawns: Array[Vector2i] = []
	
	var tiles = tile_map.get_used_cells(0)
	
	while len(enemy_spawns) < enemy_spawn_count:
		var pos = tiles.pick_random()
		if pos in enemy_spawns or Vector2(pos).distance_to(center_tile) < 5:
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
		spawn_container.add_child.call_deferred(new)
	
func _on_ui_start_game_requested():
	for child in spawn_container.get_children():
		child.queue_free()
		
	var player = player_scene.instantiate()
	player.position = center_tile * tile_map.rendering_quadrant_size
	player.health_component.died.connect($UI.show_game_over)
	spawn_container.add_child.call_deferred(player)
	player_spawned.emit(player)
	
	_spawn_enemies()
