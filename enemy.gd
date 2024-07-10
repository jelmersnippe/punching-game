extends CharacterBody2D
class_name Enemy

@export var speed = 50
@export var knockback_recovery_speed = 5

@export var base_health = 10:
	set(value):
		base_health = value
		$Healthbar.max_value = value
var current_health:
	set(value):
		current_health = value
		$Healthbar.value = current_health

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

func is_grounded() -> bool:
	return $GroundedRaycast.is_colliding()

func _process(delta):
	if velocity.x > 0:
		$Sprite2D.flip_h = false
		
	elif velocity.x < 0:
		$Sprite2D.flip_h = true
	
	if knocked:
		$RayCast2D.target_position = velocity * delta * 2
		
		if $RayCast2D.is_colliding():
			velocity = velocity.bounce($RayCast2D.get_collision_normal())
		
		knocked_grace_time -= delta
		velocity -= velocity.normalized() * knockback_recovery_speed
		
		if abs(velocity) < Vector2(0.5, 0.5):
			knocked = false
		
	move_and_slide()
	
func knockback(normalized_impact_direction: Vector2, force: float):
	if knocked: 
		return
		
	knocked = true
	velocity = normalized_impact_direction * force

func take_damage(damage: int):
	current_health = clamp(current_health - damage, 0, base_health)
	
	if current_health <= 0:
		queue_free()

func _on_hitbox_area_entered(area):
	if not knocked:
		return
		
	var parent = area.get_parent()
	if parent is Enemy:
		var enemy = parent as Enemy
		if enemy.remaining_knocked_grace_time > 0:
			return
		enemy.knockback(velocity.normalized(), (velocity.x + velocity.y) / 2)
		enemy.take_damage((velocity.x + velocity.y) / 120)
		velocity /= 3
