extends Node
class_name MovementComponent

signal collided(collision: KinematicCollision2D)

@export var body: CharacterBody2D
@export var velocity_component: VelocityComponent

func _process(delta: float):
	_move(delta)

func _move(delta: float):
	body.velocity = velocity_component.velocity
	var collision = body.move_and_collide(body.velocity * delta, true)
	body.move_and_slide()
	
	if collision != null:
		collided.emit(collision)
	
