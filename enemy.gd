extends CharacterBody2D
class_name Enemy

@export var hit_sound: AudioStream

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

var knocked_grace_time = 0.1
var remaining_knocked_grace_time = 0

var current_state: State = State.WANDERING:
	set(value):
		current_state = value
		$Label.text = State.keys()[value]
enum State {
	WANDERING,
	FOLLOWING,
	KNOCKED
}

var target: Node2D = null

@onready var shader_material = $Sprite.material as ShaderMaterial

func _ready():
	current_state = State.WANDERING
	wander_target = position
	current_health = base_health
	
	var detection_shape = CircleShape2D.new()
	detection_shape.radius = detection_range
	$DetectionRange/CollisionShape2D.shape = detection_shape

func _process(delta):
	if velocity.x > 0:
		$Sprite.flip_h = false
	elif velocity.x < 0:
		$Sprite.flip_h = true
	
	match current_state:
		State.KNOCKED:
			_knocked_behavior(delta)
		State.WANDERING:
			_wander_behavior(delta)
		State.FOLLOWING:
			_follow_behavior()
			
	move_and_slide()

func _knocked_behavior(delta):
	if current_state != State.KNOCKED:
		return
		
	$RayCast2D.target_position = velocity * delta * 2
	
	if $RayCast2D.is_colliding():
		take_damage(1, Vector2.ZERO - velocity.normalized())
		velocity = velocity.bounce($RayCast2D.get_collision_normal())
		velocity /= 3
	
	remaining_knocked_grace_time -= delta
	velocity -= velocity.normalized() * knockback_recovery_speed
	
	if velocity.distance_to(Vector2.ZERO) < 5:
		_reset_sprite()
		wander_target = position
		current_state = State.WANDERING
	
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
		
	velocity = direction * speed
	
	$RayCast2D.target_position = velocity * delta * 10
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
		
	velocity = direction * speed
	
func knockback(normalized_impact_direction: Vector2, force: float):
	if current_state == State.KNOCKED: 
		return
		
	remaining_knocked_grace_time = knocked_grace_time
	current_state = State.KNOCKED
	velocity = normalized_impact_direction * force
	print(get_name() + " knocked with velocity " + str(velocity))

func take_damage(damage: int, hit_direction: Vector2):
	current_health = clamp(current_health - damage, 0, base_health)
	
	SoundManager.play_sound(hit_sound, 0)
	shader_material.set_shader_parameter("active", true)
	$Sprite.frame = 1
	var hit_flash_timer = get_tree().create_timer(0.1)
	hit_flash_timer.timeout.connect(_reset_color)
	
	$HitParticles.direction = hit_direction
	$HitParticles.emitting = true
	
	if current_health <= 0:
		$DeathParticles.emitting = true
		var death_timer = get_tree().create_timer($DeathParticles.lifetime)
		death_timer.timeout.connect(queue_free)
		
func _reset_color():
	shader_material.set_shader_parameter("active", false)
	
func _reset_sprite():
	$Sprite.frame = 0
	
func _on_hitbox_area_entered(area):
	if current_state != State.KNOCKED:
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
		enemy.take_damage(damage, area.position.direction_to(position).normalized())
		velocity /= 4
		print(get_name() + " slowed to " + str(velocity))
			

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
