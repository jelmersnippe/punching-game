extends Node2D

var target_scene = preload("res://target.tscn")
var target_positions: Array[Vector2]

func _ready():
	var targets = get_tree().get_nodes_in_group("target")
	
	for target in targets:
		target_positions.append(target.position)

func _respawn_targets():
	for t_pos in target_positions:
		var t = target_scene.instantiate()
		t.position = t_pos
		add_child(t)
	
func _on_player_just_landed():
	_respawn_targets()
