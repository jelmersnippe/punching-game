extends CharacterBody2D

const SPEED = 300.0

const TIME_TO_MAX_CHARGE = 1.5
const MAX_CHARGE = 600
const AIR_TIME = 0.2
const AIR_HOLD_GRACE_TIME = 0.2
var CHARGE_SPEED = MAX_CHARGE / TIME_TO_MAX_CHARGE

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var current_charge: float = 0
@export var remaining_air_time: float = 0
@export var remaining_air_hold_grace_time: float = 0

@export var available_charges = 0

func _draw():
	var distance = current_charge * AIR_TIME
	var direction = (get_global_mouse_position() - global_position).normalized()
	draw_line(Vector2(0, 0), distance * direction, Color.REBECCA_PURPLE, 2)

func _physics_process(delta):
	if not is_on_floor():
		_handle_airborne(delta)
	else:
		_handle_grounded(delta)

	move_and_slide()
	
	return
	
	if Input.is_action_just_pressed("charge") and not is_on_floor():
		remaining_air_hold_grace_time = AIR_HOLD_GRACE_TIME

	if Input.is_action_pressed("charge") and available_charges > 0:
		current_charge += CHARGE_SPEED * delta
		if current_charge > MAX_CHARGE:
			current_charge = MAX_CHARGE
		elif not is_on_floor():
			velocity = Vector2(0, 0)
			
		queue_redraw()
		

func _on_punch_area_area_entered(area):
	if area.is_in_group("target"):
		area.queue_free()
		available_charges += 1
		
func _handle_grounded(delta: float):
	if not is_on_floor():
		return
		
	remaining_air_time = 0
	remaining_air_hold_grace_time = 0
	available_charges = 1
		
	var input = Input.get_axis("move_left", "move_right")
	if input:
		velocity.x = input * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if Input.is_action_pressed("charge") and available_charges > 0:
		_charge(delta)
		
	if Input.is_action_just_released("charge"):
		_release_charge()
		
func _charge(delta: float):
	current_charge += CHARGE_SPEED * delta
	if current_charge > MAX_CHARGE:
		current_charge = MAX_CHARGE
		
	queue_redraw()
	
func _release_charge():
	if current_charge <= 0 or available_charges <= 0:
		return
		
	remaining_air_time = (current_charge / MAX_CHARGE) * AIR_TIME
	current_charge = 0
	available_charges -= 1
	
	var direction = (get_global_mouse_position() - global_position).normalized()
	velocity = direction * MAX_CHARGE
	queue_redraw()
	
func _handle_airborne(delta: float):
	if is_on_floor():
		return
		
	if remaining_air_time <= 0:
		velocity.y += gravity * delta
	else:
		remaining_air_time -= delta
		if remaining_air_time <= 0:
			velocity /= 4
