extends Node2D

@export var lifetime: float = 0.2
@export var speed: int = 200

func _process(delta):
	position += transform.x * speed * delta
