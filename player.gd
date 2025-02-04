extends CharacterBody2D

signal just_landed()

@export var SPEED = 300.0
@export var CHARGE_SLOWDOWN = 0.3
@export var TIME_TO_MAX_CHARGE = 1
@export var MAX_CHARGE = 600
@export var AIR_TIME = 0.2
@export var AIR_HOLD_GRACE_TIME = 0.2

var CHARGE_SPEED: int = MAX_CHARGE / TIME_TO_MAX_CHARGE

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var current_charge: float = 0
@export var remaining_air_time: float = 0:
	set(value):
		remaining_air_time = value
		if remaining_air_time <= 0:
			$Sprite2D/Hand.position = Vector2(-3, 3)
			$Sprite2D/Hand2.position = Vector2(3, 3)
@export var remaining_air_hold_grace_time: float = 0

@export var available_charges = 0

var is_grounded = false

func _set_release_hands():
	if velocity.x > 0:
		$Sprite2D/Hand.position = Vector2(8, 3)
		$Sprite2D/Hand2.position = Vector2(3, 3)
	else:
		$Sprite2D/Hand.position = Vector2(-3, 3)
		$Sprite2D/Hand2.position = Vector2(-8, 3)

func _set_charging_hands():
	var direction = (get_global_mouse_position() - global_position).normalized()
	if direction.x > 0:
		$Sprite2D/Hand.position = Vector2(-8, 3)
		$Sprite2D/Hand2.position = Vector2(3, 3)
	else:
		$Sprite2D/Hand.position = Vector2(-3, 3)
		$Sprite2D/Hand2.position = Vector2(8, 3)
		
func _draw():
	var distance = current_charge * AIR_TIME
	var direction = (get_global_mouse_position() - global_position).normalized()
	draw_line(Vector2(0, 0), distance * direction, Color.REBECCA_PURPLE, 2)
	
	$Sprite2D.flip_h = direction.x < 0

func _physics_process(delta):
	if is_on_floor():
		if not is_grounded:
			just_landed.emit()
		_handle_grounded(delta)
	else:
		_handle_airborne(delta)
		
	is_grounded = is_on_floor()
	
	if remaining_air_time > 0:
		remaining_air_time -= delta
		if remaining_air_time <= 0:
			velocity /= 4
			
	move_and_slide()
	
func _handle_airborne(delta: float):
	if is_on_floor():
		return
		
	if remaining_air_time <= 0:
		velocity.y += gravity * delta
			
	if Input.is_action_just_pressed("charge") and available_charges > 0:
		remaining_air_hold_grace_time = AIR_HOLD_GRACE_TIME
			
	if Input.is_action_pressed("charge"):
		var did_charge = _charge(delta)
		if did_charge:
			velocity = Vector2.ZERO
		elif remaining_air_hold_grace_time > 0:
			velocity = Vector2.ZERO
			remaining_air_hold_grace_time -= delta
		
	if Input.is_action_just_released("charge"):
		_release_charge()
		remaining_air_hold_grace_time = 0
		
func _handle_grounded(delta: float):
	if not is_on_floor() or remaining_air_time > 0:
		return
		
	remaining_air_time = 0
	remaining_air_hold_grace_time = 0
	available_charges = 1
		
	var input = Input.get_axis("move_left", "move_right")
	if input:
		velocity.x = input * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if input == 1:
		$Sprite2D.flip_h = false
	elif input == -1:
		$Sprite2D.flip_h = true
		
	if Input.is_action_pressed("charge"):
		velocity.x *= CHARGE_SLOWDOWN
		_charge(delta)
		
	if Input.is_action_just_released("charge"):
		_release_charge()
		
func _charge(delta: float) -> bool:
	if available_charges <= 0:
		return false
		
	_set_charging_hands()
	
	if current_charge >= MAX_CHARGE:
		current_charge = MAX_CHARGE
		queue_redraw()
		return false
		
	current_charge = min(current_charge + CHARGE_SPEED * delta, MAX_CHARGE)
		
	queue_redraw()
	return true
	
func _release_charge():
	if current_charge <= 0 or available_charges <= 0:
		return
		
	remaining_air_time = (current_charge / MAX_CHARGE) * AIR_TIME
	current_charge = 0
	available_charges -= 1
	
	var direction = (get_global_mouse_position() - global_position).normalized()
	velocity = direction * MAX_CHARGE
	_set_release_hands()
	queue_redraw()
		
func _on_punch_area_area_entered(area: Area2D):
	if area.is_in_group("target"):
		available_charges += 1
		area.queue_free()
	elif remaining_air_time > 0:
		if area.is_in_group("breakable"):
			area.get_parent().queue_free()
		elif area is Enemy:
			var enemy = area as Enemy
			var impact_force = (remaining_air_time / AIR_TIME) * MAX_CHARGE
			print("impact force: " + str(impact_force))
			enemy.knockback(position.direction_to(enemy.position), impact_force)
			enemy.take_damage(impact_force / 120)
			velocity /= 4
		else:
			area.get_parent().apply_central_impulse(velocity)
