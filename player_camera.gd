extends Camera2D

var target: Node2D

@export var max_offset = 100
@export var smoothing = 5

func _physics_process(delta):
	if target == null:
		return
		
	var screen_size = Vector2(get_viewport().size)
		
	var mouse_position = get_global_mouse_position()
	var direction = target.global_position.direction_to(mouse_position)
	
	var distance_to_edge = (screen_size / 2).length()
	var mouse_relative_to_screen_center = mouse_position - (screen_size / 2)
	var mouse_distance = mouse_relative_to_screen_center.length()
	var offset = direction * lerp(0, max_offset, mouse_distance / distance_to_edge)
	
	var desired_position = target.global_position + offset
	
	global_position = global_position.lerp(desired_position, smoothing * delta)
	
func _on_main_player_spawned(player: Player):
	target = player
