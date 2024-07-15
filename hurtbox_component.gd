extends Area2D
class_name HurtboxComponent

@export var health_component: HealthComponent

signal hit_from(direction: Vector2)
signal hit()

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	print(get_parent().get_name() + " got hit by " + area.get_parent().get_name())
	if not area is HitboxComponent:
		print("not hitbox")
		return
		
	print("hitbox")
		
	var hitbox = area as HitboxComponent
	var direction = global_position.direction_to(area.global_position)
	hit_from.emit(direction)
	hit.emit()
	
	if health_component == null:
		return
		
	health_component.take_damage(hitbox.contact_damage)
