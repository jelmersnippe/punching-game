extends CharacterBody2D
class_name Enemy

@export var velocity_component: VelocityComponent
@export var knockable_component: KnockableComponent

@export var hit_sound: AudioStream

@export var speed = 50
@export var knockback_recovery_speed = 5

@export var wander_range: Vector2 = Vector2(200, 200)
@export var detection_range: float = 100

var current_state: State = State.WANDERING:
	set(value):
		current_state = value
		$Label.text = State.keys()[value]
		
enum State {
	WANDERING,
	FOLLOWING
}

var target: Node2D = null

func _ready():
	current_state = State.WANDERING
	wander_target = position
	
	var detection_shape = CircleShape2D.new()
	detection_shape.radius = detection_range
	$DetectionRange/CollisionShape2D.shape = detection_shape

func _move():
	velocity = velocity_component.velocity
	move_and_slide()

func _process(delta):
	if knockable_component.is_knocked:
		_move()
		return
		
	match current_state:
		State.WANDERING:
			_wander_behavior(delta)
		State.FOLLOWING:
			_follow_behavior()
	
	if velocity_component.velocity.x > 0:
		$Sprite.flip_h = false
	elif velocity_component.velocity.x < 0:
		$Sprite.flip_h = true
		
	_move()
	
var wander_target: Vector2
func _wander_behavior(delta):
	if current_state != State.WANDERING:
		return
		
	if target != null:
		current_state = State.FOLLOWING
		return
		
	if position.distance_to(wander_target) < 2:
		wander_target = position + Vector2(randf_range(-wander_range.x, wander_range.x), randf_range(-wander_range.y, wander_range.y))
		
	var direction = position.direction_to(wander_target)
		
	velocity_component.velocity = direction * speed
	
	$RayCast2D.target_position = velocity_component.velocity * delta * 10
	if $RayCast2D.is_colliding():
		wander_target = position + Vector2(randf_range(-wander_range.x, wander_range.x), randf_range(-wander_range.y, wander_range.y))
	
func _follow_behavior():
	if current_state != State.FOLLOWING:
		return
		
	if target == null:
		current_state = State.WANDERING
		return
	
	$NavigationAgent2D.target_position = target.position
	var position_to_move_to = $NavigationAgent2D.get_next_path_position()
	var direction = position.direction_to(position_to_move_to)
		
	velocity_component.velocity = direction * speed
	
func _on_detection_range_body_entered(body):
	if current_state != State.WANDERING:
		return
		
	if not body is Player:
		return
		
	target = body
	current_state = State.FOLLOWING

func _on_detection_range_body_exited(body):
	if current_state != State.FOLLOWING:
		return
		
	if body != target:
		return
		
	target = null
	wander_target = position
	current_state = State.WANDERING

func _on_health_component_died():
	queue_free()

func _on_knockable_component_on_knocked_changed(is_knocked):
	if is_knocked:
		$Sprite.frame = 1
	else:
		$Sprite.frame = 0
