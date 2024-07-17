extends CharacterBody2D
class_name Enemy

@export var velocity_component: VelocityComponent

@export var knockable_component: KnockableComponent

@export var hit_sound: AudioStream

@export var speed = 50

@export var wander_range: Vector2 = Vector2(200, 200)
@export var detection_range: float = 100

@export var attack: Attack

var current_state: State = State.WANDERING:
	set(value):
		current_state = value
		$Label.text = State.keys()[value]
		
enum State {
	IDLE,
	WANDERING,
	FOLLOWING,
	SEEKING,
	ATTACKING
}

@export var wander_idle_time_min: float = 1
@export var wander_idle_time_max: float = 4

var target: Node2D = null

func _ready():
	current_state = State.WANDERING
	target_position = position
	
	var detection_shape = CircleShape2D.new()
	detection_shape.radius = detection_range
	$DetectionRange/CollisionShape2D.shape = detection_shape
	$BounceComponent/Toggleable.disable()
	
	if attack != null:
		attack.attack_completed.connect(func(): current_state = State.FOLLOWING)

func _process(delta):
	if knockable_component.is_knocked:
		return
		
	match current_state:
		State.IDLE:
			return
		State.WANDERING:
			_wander_behavior(delta)
		State.FOLLOWING:
			_follow_behavior()
		State.SEEKING:
			_seeking_behavior()
		State.ATTACKING:
			return
	
	if velocity_component.velocity.x > 0:
		$Sprite.flip_h = false
	elif velocity_component.velocity.x < 0:
		$Sprite.flip_h = true
	
var target_position: Vector2
func _wander_behavior(delta):
	if current_state != State.WANDERING:
		return
		
	if target != null:
		current_state = State.FOLLOWING
		return
		
	if position.distance_to(target_position) < 2:
		velocity_component.velocity = Vector2.ZERO
		var timer = get_tree().create_timer(randf_range(wander_idle_time_min, wander_idle_time_max))
		timer.timeout.connect(_set_wander_position)
		current_state = State.IDLE
		return
		
	var direction = position.direction_to(target_position)
		
	velocity_component.velocity = direction * speed
	
	$RayCast2D.target_position = velocity_component.velocity * delta * 10
	if $RayCast2D.is_colliding():
		target_position = position + Vector2(randf_range(-wander_range.x, wander_range.x), randf_range(-wander_range.y, wander_range.y))
	
func _set_wander_position():
	if current_state != State.IDLE:
		return
	target_position = position + Vector2(randf_range(-wander_range.x, wander_range.x), randf_range(-wander_range.y, wander_range.y))
	current_state = State.WANDERING
	
func _seeking_behavior():
	if current_state != State.SEEKING:
		return
		
	if position.distance_to(target_position) < 2:
		if target_position == $NavigationAgent2D.get_final_position():
			current_state = State.WANDERING
			return
			
		target_position = $NavigationAgent2D.get_next_path_position()
	
	var direction = position.direction_to(target_position)
		
	velocity_component.velocity = direction * speed
	
func _follow_behavior():
	if current_state != State.FOLLOWING:
		return
		
	if target == null:
		current_state = State.SEEKING
		return
		
	if attack != null and global_position.distance_to(target.global_position) <= attack.prefered_distance:
		velocity_component.velocity = Vector2.ZERO
		if attack.can_attack:
			attack.execute(target)
			current_state = State.ATTACKING
		return
	
	$NavigationAgent2D.target_position = target.position
	target_position = $NavigationAgent2D.get_next_path_position()
	var direction = position.direction_to(target_position)
		
	velocity_component.velocity = direction * speed
	
func _on_detection_range_body_entered(body):
	if current_state == State.FOLLOWING:
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
	current_state = State.SEEKING

func _on_health_component_died():
	queue_free()

func _on_knockable_component_on_knocked_changed(is_knocked):
	if is_knocked:
		$KnockbackComponent.set_collision_layer_value(1, true)
		$KnockbackComponent.set_collision_layer_value(4, false)
		$KnockbackComponent.set_collision_mask_value(1, false)
		$KnockbackComponent.set_collision_mask_value(4, true)
		
		$HitboxComponent.set_collision_layer_value(1, true)
		$HitboxComponent.set_collision_layer_value(4, false)
		$HitboxComponent.set_collision_mask_value(1, false)
		$HitboxComponent.set_collision_mask_value(4, true)
		
		$BounceComponent/Toggleable.enable()
		$Sprite.frame = 1
		attack.cancel()
	else:
		$KnockbackComponent.set_collision_layer_value(1, false)
		$KnockbackComponent.set_collision_layer_value(4, true)
		$KnockbackComponent.set_collision_mask_value(1, false)
		$KnockbackComponent.set_collision_mask_value(4, false)
		
		$HitboxComponent.set_collision_layer_value(1, false)
		$HitboxComponent.set_collision_layer_value(4, true)
		$HitboxComponent.set_collision_mask_value(1, false)
		$HitboxComponent.set_collision_mask_value(4, false)
		
		$BounceComponent/Toggleable.disable()
		$Sprite.frame = 0
