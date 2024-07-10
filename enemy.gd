extends Area2D

@export var speed = 100
var direction = Vector2.RIGHT

var velocity = Vector2.ZERO

func _process(delta):
	if not $GroundedRaycast.is_colliding():
		velocity.y += 9.8
	else:
		velocity.y = 0
		global_position.y = $GroundedRaycast.get_collision_point().y - $GroundedRaycast.target_position.y
		if $WallRaycast.is_colliding() or not $FloorRaycast.is_colliding():
			_turn()
			
		velocity = direction * speed
	
	position += velocity * delta
		
func _turn():
	$Sprite2D.flip_h = !$Sprite2D.flip_h
	direction = Vector2(-direction.x, 0)
	$WallRaycast.target_position.x = -$WallRaycast.target_position.x
	$FloorRaycast.target_position.x = -$FloorRaycast.target_position.x
