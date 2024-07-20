extends StaticBody2D

@export var lifetime: float = 1.5
@export var speed: int = 200

func _ready():
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _process(delta):
	var collision = move_and_collide(transform.x * speed * delta)
	
	if collision != null:
		var timer = get_tree().create_timer(0.1)
		timer.timeout.connect(queue_free)
