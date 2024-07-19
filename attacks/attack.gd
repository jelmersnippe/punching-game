extends Node2D
class_name Attack

signal cooldown_ready()
signal attack_completed()

@export var cooldown: float = 5
@export var prefered_distance: float = 15

var can_attack: bool = false
var attacking: bool = false

func _ready():
	var timer = get_tree().create_timer(3)
	timer.timeout.connect(_finish_cooldown)

func execute(_target: Node2D):
	if not can_attack:
		return
		
	pass
	
func cancel():
	if not attacking:
		return
		
	_complete_attack()
	pass
		
func _complete_attack():
	can_attack = false
	attacking = false
	attack_completed.emit()
	
	var timer = get_tree().create_timer(cooldown)
	timer.timeout.connect(_finish_cooldown)
	
func _finish_cooldown():
	can_attack = true
	cooldown_ready.emit()
