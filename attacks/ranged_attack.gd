extends Attack

@export var projectile_scene: PackedScene
@export var spawn_point: Node2D

func execute(target: Node2D):
	if not can_attack:
		return
	
	attacking = true
	can_attack = false
	var projectile = projectile_scene.instantiate() as Node2D
	projectile.global_position = spawn_point.global_position
	projectile.look_at(target.global_position)
	get_tree().get_root().add_child(projectile)
	
	print("ranged attack done")
	_complete_attack()
