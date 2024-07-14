extends CharacterBody2D
class_name Player

signal health_changed(current: int, max: int)
signal damage_received(amount: int)

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

@export var current_charge: float = 0
@export var remaining_punch_time: float = 0:
	set(value):
		remaining_punch_time = value
		if remaining_punch_time <= 0:
			_reset_hands()

func _reset_hands():
	$Sprite/Hand.position = Vector2(-3, 3)
	$Sprite/Hand2.position = Vector2(3, 3)

func _set_release_hands():
	if velocity.x > 0:
		$Sprite/Hand.position = Vector2(8, 3)
		$Sprite/Hand2.position = Vector2(3, 3)
	else:
		$Sprite/Hand.position = Vector2(-3, 3)
		$Sprite/Hand2.position = Vector2(-8, 3)

func _set_charging_hands():
	var direction = (get_global_mouse_position() - global_position).normalized()
	if direction.x > 0:
		$Sprite/Hand.position = Vector2(-8, 3)
		$Sprite/Hand2.position = Vector2(3, 3)
	else:
		$Sprite/Hand.position = Vector2(-3, 3)
		$Sprite/Hand2.position = Vector2(8, 3)
		
func _draw():
	var distance = current_charge * PUNCH_TIME
	var direction = (get_global_mouse_position() - global_position).normalized()
	draw_line(Vector2(0, 0), distance * direction, Color.REBECCA_PURPLE, 2)
	
	$Sprite.flip_h = direction.x < 0

func _physics_process(delta):
	if knocked:
		move_and_slide()
		return
	
	_handle_grounded(delta)
	
	if remaining_punch_time > 0:
		remaining_punch_time -= delta
		if remaining_punch_time <= 0:
			velocity /= 4
			$TrailingParticles.emitting = false
	if remaining_charge_cooldown > 0:
		remaining_charge_cooldown -= delta
			
	move_and_slide()
		
func _handle_grounded(delta: float):
	if remaining_punch_time > 0:
		return
		
	var input = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")).normalized()
	velocity = input * SPEED
		
	if input.x > 0:
		$Sprite.flip_h = false
	elif input.x < 0:
		$Sprite.flip_h = true
		
	if Input.is_action_pressed("charge"):
		if current_charge <= 0 and remaining_charge_cooldown <= 0:
			charge_sound_player = SoundManager.play_sound(charge_sound, -20)
			
		velocity *= CHARGE_SLOWDOWN
		_charge(delta)
		
	if Input.is_action_just_released("charge"):
		_release_charge()
		
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
	velocity = direction * MAX_CHARGE
	_set_release_hands()
	$TrailingParticles.emitting = true
	queue_redraw()
	
	for area in $PunchArea.get_overlapping_areas():
		_on_punch_area_area_entered(area)
		
func _on_punch_area_area_entered(area: Area2D):
	if remaining_punch_time > 0:
		var parent = area.get_parent()
		if parent is Enemy:
			var enemy = parent as Enemy
			var impact_force = (remaining_punch_time / PUNCH_TIME) * MAX_CHARGE
			var direction = position.direction_to(enemy.position)
			enemy.knockback(direction.normalized(), impact_force)
			enemy.take_damage(impact_force / 120, direction.normalized())
			velocity /= 4

@export var starting_health = 10:
	set(value):
		starting_health = value
		health_changed.emit(current_health, starting_health)
var current_health: int:
	set(value):
		current_health = value
		health_changed.emit(current_health, starting_health)

func _ready():
	current_health = starting_health
	
func _cancel_charge():
	remaining_charge_cooldown = charge_cooldown
	current_charge = 0
	_reset_hands()
	queue_redraw()
	if charge_sound_player != null:
		charge_sound_player.stop()
	
var knocked = false
func _knockback(normalized_impact_direction: Vector2, force: float, time: float):
	knocked = true
	_cancel_charge()
	velocity = normalized_impact_direction * force
	print(get_name() + " knocked with velocity " + str(velocity))
	
	var timer = get_tree().create_timer(time)
	timer.timeout.connect(func(): knocked = false)

@onready var shader_material = $Sprite.material as ShaderMaterial

func _reset_color():
	shader_material.set_shader_parameter("active", false)

@export var hit_sound: AudioStream
func take_damage(damage: int, hit_direction: Vector2):
	current_health = clamp(current_health - damage, 0, starting_health)
	damage_received.emit(damage)
	
	SoundManager.play_sound(hit_sound, 0)
	shader_material.set_shader_parameter("active", true)
	var hit_flash_timer = get_tree().create_timer(0.1)
	hit_flash_timer.timeout.connect(_reset_color)
	
	$HitParticles.direction = hit_direction
	$HitParticles.emitting = true
	
	if current_health <= 0:
		$DeathParticles.emitting = true
		var death_timer = get_tree().create_timer($DeathParticles.lifetime)
		death_timer.timeout.connect(queue_free)


func _on_hurtbox_area_entered(area):
	if remaining_punch_time > 0:
		return
		
	var parent = area.get_parent()
	if parent is Enemy:
		var enemy = parent as Enemy
		var direction = enemy.position.direction_to(position)
		_knockback(direction.normalized(), 200, 0.2)
		take_damage(2, direction)
