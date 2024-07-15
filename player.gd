extends CharacterBody2D
class_name Player

@export var health_component: HealthComponent
@export var knockable_component: KnockableComponent
@export var velocity_component: VelocityComponent

@export var punch_sound: AudioStream
@export var charge_sound: AudioStream
var charge_sound_player: AudioStreamPlayer2D

@export var SPEED = 300.0
@export var CHARGE_SLOWDOWN = 0.3
@export var TIME_TO_MAX_CHARGE = 1
@export var MAX_CHARGE = 600
@export var PUNCH_TIME = 0.2

var CHARGE_SPEED: int = MAX_CHARGE / TIME_TO_MAX_CHARGE

@export var charge_cooldown = 1
var remaining_charge_cooldown = 0

var default_cue_position: Vector2

@export var current_charge: float = 0
@export var remaining_punch_time: float = 0:
	set(value):
		remaining_punch_time = value
		if remaining_punch_time <= 0:
			_reset_hands()

func _reset_hands():
	$RotationPoint/Cue/CollisionShape2D.disabled = true
	$RotationPoint/KnockbackComponent/CollisionShape2D.disabled = true
	
	$HurtboxComponent/CollisionShape2D.disabled = false
	$KnockableComponent/CollisionShape2D.disabled = false
	
	$RotationPoint/Cue.position = default_cue_position

func _set_release_hands():
	$RotationPoint/Cue/CollisionShape2D.disabled = false
	$RotationPoint/KnockbackComponent/CollisionShape2D.disabled = false
	
	$HurtboxComponent/CollisionShape2D.disabled = true
	$KnockableComponent/CollisionShape2D.disabled = true
	
	$RotationPoint/Cue.position = default_cue_position + Vector2(5,0)

func _set_charging_hands():
	$RotationPoint/Cue.position = default_cue_position - Vector2(5,0)
		
func _draw():
	var distance = current_charge * PUNCH_TIME
	var direction = $RotationPoint/Cue.global_position.direction_to(get_global_mouse_position())
	var cue_position = Vector2.ZERO + $RotationPoint.position + $RotationPoint/Cue.position
	draw_line(cue_position, cue_position + distance * direction, Color.REBECCA_PURPLE, 2)

func _move():
	velocity = velocity_component.velocity
	move_and_slide()
	
func _physics_process(delta):
	if knockable_component.is_knocked:
		_move()
		return
		
	$RotationPoint.look_at(get_global_mouse_position())
	var cue_rotation = fmod(fmod($RotationPoint.rotation_degrees, 360) + 360, 360)
	if cue_rotation > 180 and cue_rotation < 360:
		$RotationPoint.z_index = -1
	else:
		$RotationPoint.z_index = 1
	
	_handle_grounded(delta)
	
	if remaining_punch_time > 0:
		remaining_punch_time -= delta
		if remaining_punch_time <= 0:
			velocity_component.velocity /= 4
			$TrailingParticles.emitting = false
	if remaining_charge_cooldown > 0:
		remaining_charge_cooldown -= delta
			
	_move()
		
func _handle_grounded(delta: float):
	if remaining_punch_time > 0:
		return
		
	var input = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")).normalized()
	velocity_component.velocity = input * SPEED
		
	var face_direction = global_position.direction_to(get_global_mouse_position())
	if face_direction.x > 0:
		$Sprite.flip_h = false
	elif face_direction.x < 0:
		$Sprite.flip_h = true
		
	if Input.is_action_pressed("charge"):
		if current_charge <= 0 and remaining_charge_cooldown <= 0:
			charge_sound_player = SoundManager.play_sound(charge_sound, -20)
			
		velocity_component.velocity *= CHARGE_SLOWDOWN
		_charge(delta)
		
	if Input.is_action_just_released("charge"):
		_release_charge()
		
	if velocity_component.velocity.length() > 0:
		$Sprite.animation = "run"
	else:
		$Sprite.animation = "idle"
		
func _charge(delta: float):
	if remaining_charge_cooldown > 0:
		return
	_set_charging_hands()
	
	current_charge = min(current_charge + CHARGE_SPEED * delta, MAX_CHARGE)
		
	queue_redraw()
	
func _release_charge():
	if current_charge <= 0 :
		return
		
	remaining_charge_cooldown = charge_cooldown
		
	if charge_sound_player != null:
		charge_sound_player.stop()
		
	remaining_punch_time = (current_charge / MAX_CHARGE) * PUNCH_TIME
	current_charge = 0
	
	SoundManager.play_sound(punch_sound, -10)
	var direction = (get_global_mouse_position() - global_position).normalized()
	velocity_component.velocity = direction * MAX_CHARGE
	
	$RotationPoint/KnockbackComponent.knockback_force = MAX_CHARGE
	$RotationPoint/KnockbackComponent.knockback_time = remaining_punch_time
	
	_set_release_hands()
	$TrailingParticles.emitting = true
	queue_redraw()
	
func _ready():
	default_cue_position = $RotationPoint/Cue.position
	
func _cancel_charge():
	remaining_charge_cooldown = charge_cooldown
	current_charge = 0
	_reset_hands()
	queue_redraw()
	if charge_sound_player != null:
		charge_sound_player.stop()

@export var hit_sound: AudioStream

func _on_knockable_component_on_knocked_changed(is_knocked):
	if not is_knocked:
		return
		
	_cancel_charge()
