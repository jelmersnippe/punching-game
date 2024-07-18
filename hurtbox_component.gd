extends Area2D
class_name HurtboxComponent

@export var health_component: HealthComponent

signal hit_from(direction: Vector2)
signal hit()

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if not area is HitboxComponent:
		return
		
	var hitbox = area as HitboxComponent
	var direction = global_position.direction_to(area.global_position)
	hit_from.emit(direction)
	hit.emit()
	
	if health_component == null:
		return
		
	health_component.take_damage(hitbox.contact_damage)
