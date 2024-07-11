extends CharacterBody2D
class_name Enemy

@export var speed = 50
@export var knockback_recovery_speed = 5

@export var wander_range: Vector2 = Vector2(200, 200)
@export var detection_range: float = 100

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

var current_state: State = State.WANDERING
enum State {
	WANDERING,
	FOLLOWING
}

var target: Node2D = null

func _ready():
	current_state = State.WANDERING
	wander_target = position
	current_health = base_health
	
	var detection_shape = CircleShape2D.new()
	detection_shape.radius = detection_range
	$DetectionRange/CollisionShape2D.shape = detection_shape

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
			wander_target = position
			velocity = Vector2.ZERO
	else:
		match current_state:
			State.WANDERING:
				_wander_behavior(delta)
			State.FOLLOWING:
				_follow_behavior()
			
	move_and_slide()
	
func _draw():
	draw_line(Vector2(0, 0), $RayCast2D.target_position, Color.RED, 2)

var wander_target: Vector2
func _wander_behavior(delta):
	if target != null:
		current_state = State.FOLLOWING
		return
		
	if position.distance_to(wander_target) < 2:
		print(get_name() + " picking new wander target because reached destination")
		wander_target = position + Vector2(randf_range(-wander_range.x, wander_range.x), randf_range(-wander_range.y, wander_range.y))
		
	var direction = (wander_target - position).normalized()
		
	velocity = direction * speed
	
	$RayCast2D.target_position = velocity * delta * 10
	queue_redraw()
	if $RayCast2D.is_colliding():
		print(get_name() + " picking new wander target because wall in front")
		wander_target = position + Vector2(randf_range(-wander_range.x, wander_range.x), randf_range(-wander_range.y, wander_range.y))
	
	
func _follow_behavior():
	if target == null:
		current_state = State.WANDERING
		return
	
	var direction = (target.position - position).normalized()
	velocity = direction * speed
	
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
			

func _on_detection_range_body_entered(body):
	if not body is Player:
		return
		
	print(get_name() + " acquired target " + body.get_name())
	target = body
	current_state = State.FOLLOWING


func _on_detection_range_body_exited(body):
	if body != target:
		return
		
	print(get_name() + " lost target " + body.get_name())
	target = null
	wander_target = position
	current_state = State.WANDERING
