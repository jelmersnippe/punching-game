extends CharacterBody2D
class_name Enemy

@export var health_component: HealthComponent
@export var hurtbox_component: HurtboxComponent
@export var velocity_component: VelocityComponent
@export var knockable_component: KnockableComponent

@export var particle_player: ParticlePlayer
@export var sound_player: SoundPlayer

@export var hit_sound: AudioStream

@export var hit_particles: PackedScene = preload("res://enemy/hit_particles.tscn")
@export var death_particles: PackedScene = preload("res://enemy/death_particles.tscn")

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
	
	if detection_range > 0:
		var detection_area = Area2D.new()
		var collision_shape = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = detection_range
		collision_shape.shape = shape
		detection_area.body_entered.connect(_on_detection_range_body_entered)
		detection_area.body_exited.connect(_on_detection_range_body_exited)
		detection_area.set_collision_mask_value(1, true)
		detection_area.add_child(collision_shape)
		add_child(detection_area)
		
	$BounceComponent/Toggleable.disable()
	
	health_component.died.connect(_die)
	hurtbox_component.hit_from.connect(_hit)
	
	if attack != null:
		attack.attack_completed.connect(func(): current_state = State.FOLLOWING)
		
func _die(direction: Vector2):
	particle_player.play_particle(death_particles, global_position)
	$Sprite.play("Death")
		
func _hit(direction: Vector2):
	particle_player.play_particle(hit_particles, global_position, -direction)
	sound_player.play_sound(hit_sound, 0)

func _process(delta):
	if knockable_component.is_knocked:
		return
		
	match current_state:
		State.IDLE:
			$Sprite.play("Idle")
			return
		State.WANDERING:
			_wander_behavior(delta)
			$Sprite.play("Move")
		State.FOLLOWING:
			_follow_behavior()
			if velocity_component.velocity.length() > 0:
				$Sprite.play("Move")
			else:
				$Sprite.play("Idle")
		State.SEEKING:
			_seeking_behavior()
			$Sprite.play("Move")
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
			current_state = State.ATTACKING
			attack.execute(target)
		return
	
	$NavigationAgent2D.target_position = target.position
	target_position = $NavigationAgent2D.get_next_path_position()
	var direction = position.direction_to(target_position)
		
	velocity_component.velocity = direction * speed
	
func _on_detection_range_body_entered(body):
	if current_state == State.FOLLOWING:
		return
		
	print(body.get_name())
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

var prev_animation
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
		prev_animation = $Sprite.animation
		$Sprite.animation = "Damaged"
		if attack != null:
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
		$Sprite.play(prev_animation)
