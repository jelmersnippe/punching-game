extends Node
class_name HealthComponent

signal died()
signal health_changed(change: int, current: int, max: int)

@export var hit_particles: CPUParticles2D
@export var death_particles: CPUParticles2D

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
	
	# SoundManager.play_sound(hit_sound, 0)
	# shader_material.set_shader_parameter("active", true)
	# var hit_flash_timer = get_tree().create_timer(0.1)
	# hit_flash_timer.timeout.connect(_reset_color)
	
	# hit_particles.direction = hit_direction
	# hit_particles.emitting = true
	
	if current_health <= 0:
		die()
		
func die():
	died.emit()
	
	if death_particles:
		death_particles.emitting = true
		var death_timer = get_tree().create_timer(death_particles.lifetime)
		death_timer.timeout.connect(queue_free)
