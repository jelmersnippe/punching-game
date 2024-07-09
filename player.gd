extends CharacterBody2D

const SPEED = 300.0

const TIME_TO_MAX_CHARGE = 1.5
const MAX_CHARGE = 600
const AIR_TIME = 0.2
var CHARGE_SPEED = MAX_CHARGE / TIME_TO_MAX_CHARGE

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var current_charge: float = 0
var gravity_avoid_time: float = 0

var charge_time = 0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		if gravity_avoid_time <= 0:
			velocity.y += gravity * delta
		else:
			gravity_avoid_time -= delta
			if gravity_avoid_time <= 0:
				velocity.x = 0
				velocity.y = 0
	else: 
		gravity_avoid_time = 0

	# Handle jump.
	if Input.is_action_pressed("charge") and is_on_floor() and current_charge < MAX_CHARGE:
		current_charge += CHARGE_SPEED * delta
		if current_charge > MAX_CHARGE:
			current_charge = MAX_CHARGE
		else:
			charge_time += delta
		
	if not is_on_floor():
		move_and_slide()
		return
		
	if Input.is_action_just_released("charge") and current_charge > 0:
		velocity.y = -current_charge
		gravity_avoid_time = (current_charge / MAX_CHARGE) * AIR_TIME
		current_charge = 0
		charge_time = 0
		
		var direction = (get_global_mouse_position() - global_position).normalized()
		velocity = direction * MAX_CHARGE
	else :
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
