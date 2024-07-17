extends Area2D
class_name KnockableComponent

signal on_knocked_changed(is_knocked: bool)

@export var velocity_component: VelocityComponent

@export var mass: float = 1
@export var knockback_velocity_distance_deadzone: float = 5

var knocked_grace_time = 0.1
var is_knocked = false:
	set(value):
		is_knocked = value
		on_knocked_changed.emit(is_knocked)
var can_be_knocked = true

func _ready():
	area_entered.connect(_on_area_entered)
	
func _process(_delta):
	if not is_knocked:
		return
	
	velocity_component.velocity -= velocity_component.velocity.normalized() * mass * 5
	
	if velocity_component.velocity.length() < knockback_velocity_distance_deadzone:
		is_knocked = false

func knockback(impact_direction: Vector2, force: float) -> void:
	if is_knocked: 
		return
		
	is_knocked = true
	can_be_knocked = false
	
	var grace_timer = get_tree().create_timer(knocked_grace_time)
	grace_timer.timeout.connect(func(): can_be_knocked = true)
	
	velocity_component.velocity = impact_direction.normalized() * force

func _on_area_entered(area):
	if not area is KnockbackComponent:
		return
		
	var knockback_component = area as KnockbackComponent
	knockback(area.global_position.direction_to(global_position), knockback_component.knockback_force / mass)
