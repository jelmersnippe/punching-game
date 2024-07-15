extends Sprite2D

func _process(_delta):
	var mouse_position = get_global_mouse_position()
	global_position = mouse_position
