extends Area2D
class_name Enemy

@export var speed = 50
@export var knockback_recovery_speed = 5
@export var direction = Vector2.RIGHT

@export var base_health = 10:
	set(value):
		base_health = value
		$Healthbar.max_value = value
var current_health:
	set(value):
		current_health = value
		$Healthbar.value = current_health

var default_wall_raycast: Vector2
var default_floor_raycast: Vector2

var velocity = Vector2.ZERO
var knocked = false:
	set(value):
		knocked = value
		if knocked:
			remaining_knocked_grace_time = knocked_grace_time
		else: 
			remaining_knocked_grace_time = 0

var knocked_grace_time = 0.1

var remaining_knocked_grace_time = 0

func _ready():
	current_health = base_health
	default_wall_raycast = $WallRaycast.target_position
	default_floor_raycast = $FloorRaycast.target_position
	
	$Sprite2D.flip_h = direction.x < 0

func is_grounded() -> bool:
	return $GroundedRaycast.is_colliding()

func _process(delta):
	if knocked:
		knocked_grace_time -= delta
		velocity.x = move_toward(velocity.x, 0, knockback_recovery_speed)
		if velocity.x == 0:
			knocked = false
	
	# apply gravity
	if not is_grounded():
		velocity.y += 9.8
		
	if not knocked:
		velocity.x = direction.x * speed
		
	_set_raycasts_to_direction()
	
	# turn on wall collision or no floor in front while in control on the ground
	if $WallRaycast.is_colliding() or (not knocked and is_grounded() and not $FloorRaycast.is_colliding()):
		_turn(-velocity)
	
	position += velocity * delta
	
	# correct any vertical clipping if moving down
	if velocity.y >= 0 and is_grounded():
		velocity.y = 0
		global_position.y = $GroundedRaycast.get_collision_point().y - $GroundedRaycast.target_position.y
		
func _turn(turn_direction: Vector2):
	var turn_sign = sign(turn_direction.x)
	$Sprite2D.flip_h = turn_sign == -1
	velocity.x = abs(velocity.x) * turn_sign
	direction = Vector2(turn_sign, 0)
	_set_raycasts_to_direction()
	
func _set_raycasts_to_direction():
	if velocity.x > 0:
		$WallRaycast.target_position.x = default_wall_raycast.x
		$FloorRaycast.target_position.x = default_floor_raycast.x
	else:
		$WallRaycast.target_position.x = -default_wall_raycast.x
		$FloorRaycast.target_position.x = -default_floor_raycast.x
	
func knockback(normalized_impact_direction: Vector2, force: float):
	if knocked: 
		return
		
	knocked = true
	velocity = normalized_impact_direction * force
	_set_raycasts_to_direction()

func take_damage(damage: int):
	current_health = clamp(current_health - damage, 0, base_health)
	
	if current_health <= 0:
		queue_free()

func _on_area_entered(area):
	if not knocked:
		return
		
	if area is Enemy:
		var enemy = area as Enemy
		if enemy.remaining_knocked_grace_time > 0:
			return
		enemy.knockback(velocity.normalized(), (velocity.x + velocity.y) / 2)
		enemy.take_damage((velocity.x + velocity.y) / 120)
		enemy._turn(velocity.normalized())
		velocity /= 3
