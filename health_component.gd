extends Node
class_name HealthComponent

signal died()
signal health_changed(change: int, current: int, max: int)

@export var starting_health := 10
var max_health: int:
	set(value):
		max_health = value
		health_changed.emit(0, current_health, max_health)
var current_health: int:
	set(value):
		var health_change = value - current_health
		current_health = value
		health_changed.emit(health_change, current_health, max_health)
	
func _ready() -> void:
	max_health = starting_health
	current_health = max_health
	
func take_damage(damage: int) -> void:
	current_health = clamp(current_health - damage, 0, starting_health)
	
	
	if current_health <= 0:
		die()
		
func die():
	died.emit()
	
	queue_free()
