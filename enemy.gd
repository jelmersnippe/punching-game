extends CharacterBody2D
class_name Enemy

@export var speed = 50
@export var knockback_recovery_speed = 5
@export var velocity_deadzone = 2

@export var base_health = 10:
	set(value):
		base_health = value
		$Healthbar.max_value = value
var current_health:
	set(value):
		current_health = value
		$Healthbar.value = current_health

var knocked = false

var knocked_grace_time = 0.1

var remaining_knocked_grace_time = 0

func _ready():
	current_health = base_health

func _process(delta):
	if velocity.x > 0:
		$Sprite2D.flip_h = false
		
	elif velocity.x < 0:
		$Sprite2D.flip_h = true
	
	if knocked:
		$RayCast2D.target_position = velocity * delta * 2
		
		if $RayCast2D.is_colliding():
			velocity = velocity.bounce($RayCast2D.get_collision_normal())
			velocity /= 3
		
		remaining_knocked_grace_time -= delta
		var prev_velocity = velocity
		velocity -= velocity.normalized() * knockback_recovery_speed
		
		if sign(prev_velocity) != sign(velocity):
			knocked = false
			velocity = Vector2.ZERO
		
	move_and_slide()
	
func knockback(normalized_impact_direction: Vector2, force: float):
	if knocked: 
		return
		
	remaining_knocked_grace_time = knocked_grace_time
	knocked = true
	velocity = normalized_impact_direction * force
	print(get_name() + " knocked with velocity " + str(velocity))

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
			
		var force = abs(velocity.x) + abs(velocity.y)
		var damage = floor(clamp(force / 50, 1, 3))
		print(get_name() + " knocked " + enemy.get_name() + " dealing " + str(damage) + " damage")
		enemy.knockback(velocity.normalized(), force / 3)
		enemy.take_damage(damage)
		velocity /= 4
		print(get_name() + " slowed to " + str(velocity))
			
