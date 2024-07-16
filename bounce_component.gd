extends Node2D
class_name BounceComponent

@export var velocity_component: VelocityComponent
@export var movement_component: MovementComponent

@export var velocity_decrease_on_bounce: float = 5

func _ready():
	movement_component.collided.connect(_bounce)

func _bounce(collision: KinematicCollision2D):
	velocity_component.velocity = velocity_component.velocity.bounce(collision.get_normal())
	velocity_component.velocity -= velocity_component.velocity.normalized() * velocity_decrease_on_bounce
