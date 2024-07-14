extends Camera2D

var target: Node2D

func _physics_process(_delta):
	if target != null:
		global_position = target.global_position

func _on_main_player_spawned(player: Player):
	target = player
