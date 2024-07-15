extends ProgressBar
class_name Healthbar

@export var health_component: HealthComponent:
	set(value):
		health_component = value
		if health_component != null:
			set_health(0, health_component.current_health, health_component.max_health)
			health_component.health_changed.connect(set_health)
			
@export var label: Label

func set_health(health_change: int, current_health: int, max_health: int):
	max_value = max_health
	value = current_health
	
	if label != null:
		$Label.text = str(current_health) + "/" + str(max_health)
