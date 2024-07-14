extends Node2D

signal player_spawned(player: Node2D)

var player_scene = preload("res://player.tscn")
var enemy_scene = preload("res://enemy.tscn")

@export var enemy_spawn_count: int = 10

func _on_map_generator_map_generated(center: Vector2i, tiles: Array[Vector2i]):
	var player = player_scene.instantiate()
	player.position = center
	player.died.connect($UI.show_game_over)
	$SpawnContainer.add_child.call_deferred(player)
	player_spawned.emit(player)
	
	_spawn_enemies(center, tiles)

func _spawn_enemies(center: Vector2i, tiles: Array[Vector2i]):
	var enemy_spawns: Array[Vector2i] = []
	
	while len(enemy_spawns) < enemy_spawn_count:
		var pos = tiles.pick_random()
		if pos in enemy_spawns or Vector2(pos).distance_to(center) < 16:
			continue
		
		enemy_spawns.append(pos)
		
	for pos in enemy_spawns:
		var new = enemy_scene.instantiate()
		new.position = pos * $TileMap.rendering_quadrant_size
		$SpawnContainer.add_child.call_deferred(new)
	
func _on_ui_start_game_requested():
	for child in $SpawnContainer.get_children():
		child.queue_free()
		
	$MapGenerator.generate_map(Vector2.ZERO)
