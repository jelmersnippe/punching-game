extends CharacterBody2D

const SPEED = 300.0

const TIME_TO_MAX_CHARGE = 1.5
const MAX_CHARGE = 600
const AIR_TIME = 0.2
var CHARGE_SPEED = MAX_CHARGE / TIME_TO_MAX_CHARGE

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var current_charge: float = 0
@export var remaining_air_time: float = 0

@export var available_charges = 0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		if remaining_air_time <= 0:
			velocity.y += gravity * delta
		else:
			remaining_air_time -= delta
			if remaining_air_time <= 0:
				velocity.x = 0
				velocity.y = 0
	else: 
		remaining_air_time = 0
		if available_charges <= 0:
			available_charges = 1

	# Handle jump.
	if Input.is_action_pressed("charge") and available_charges > 0 and current_charge < MAX_CHARGE:
		velocity.y = 0
		current_charge += CHARGE_SPEED * delta
		if current_charge > MAX_CHARGE:
			current_charge = MAX_CHARGE
		
	if is_on_floor():
		velocity.x = Input.get_axis("move_left", "move_right") * SPEED
		
	if Input.is_action_just_released("charge") and current_charge > 0:
		remaining_air_time = (current_charge / MAX_CHARGE) * AIR_TIME
		current_charge = 0
		available_charges -= 1
		
		var direction = (get_global_mouse_position() - global_position).normalized()
		velocity = direction * MAX_CHARGE

	move_and_slide()


func _on_punch_area_area_entered(area):
	if area.is_in_group("target"):
		area.queue_free()
		available_charges += 1
