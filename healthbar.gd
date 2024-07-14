extends Control
class_name Healthbar

# Called when the node enters the scene tree for the first time.
func set_health(current: int, max: int):
	$Bar.max_value = max
	$Bar.value = current
	
	$Label.text = str(current) + "/" + str(max)
