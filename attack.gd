extends Node2D
class_name Attack

signal cooldown_ready()
signal attack_completed()

@export var cooldown: float = 5
@export var prefered_distance: float = 15

var can_attack: bool = true
var attacking: bool = false

func execute(_target: Node2D):
	if not can_attack:
		return
		
	pass
	
func cancel():
	print("attack cancelled")
	if not attacking:
		return
		
	print("attack cancelled")
	_complete_attack()
	pass
		
func _complete_attack():
	print("attack completed")
	attacking = false
	attack_completed.emit()
	
	var timer = get_tree().create_timer(cooldown)
	timer.timeout.connect(_finish_cooldown)
	
func _finish_cooldown():
	can_attack = true
	cooldown_ready.emit()
