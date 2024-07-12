extends CharacterBody2D
class_name Player

@export var SPEED = 300.0
@export var CHARGE_SLOWDOWN = 0.3
@export var TIME_TO_MAX_CHARGE = 1
@export var MAX_CHARGE = 600
@export var PUNCH_TIME = 0.2

var CHARGE_SPEED: int = MAX_CHARGE / TIME_TO_MAX_CHARGE

@export var current_charge: float = 0
@export var remaining_punch_time: float = 0:
	set(value):
		remaining_punch_time = value
		if remaining_punch_time <= 0:
			$Sprite2D/Hand.position = Vector2(-3, 3)
			$Sprite2D/Hand2.position = Vector2(3, 3)

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
	var distance = current_charge * PUNCH_TIME
	var direction = (get_global_mouse_position() - global_position).normalized()
	draw_line(Vector2(0, 0), distance * direction, Color.REBECCA_PURPLE, 2)
	
	$Sprite2D.flip_h = direction.x < 0

func _physics_process(delta):
	_handle_grounded(delta)
	
	if remaining_punch_time > 0:
		remaining_punch_time -= delta
		if remaining_punch_time <= 0:
			velocity /= 4
			$TrailingParticles.emitting = false
			
	move_and_slide()
		
func _handle_grounded(delta: float):
	if remaining_punch_time > 0:
		return
		
	var input = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")).normalized()
	velocity = input * SPEED
		
	if input.x > 0:
		$Sprite2D.flip_h = false
	elif input.x < 0:
		$Sprite2D.flip_h = true
		
	if Input.is_action_pressed("charge"):
		velocity *= CHARGE_SLOWDOWN
		_charge(delta)
		
	if Input.is_action_just_released("charge"):
		_release_charge()
		
func _charge(delta: float):
	_set_charging_hands()
	
	current_charge = min(current_charge + CHARGE_SPEED * delta, MAX_CHARGE)
		
	queue_redraw()
	
func _release_charge():
	if current_charge <= 0 :
		return
		
	remaining_punch_time = (current_charge / MAX_CHARGE) * PUNCH_TIME
	current_charge = 0
	
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
