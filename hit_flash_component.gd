extends Node
class_name HitFlashComponent

var hitflash_material_resource = preload("res://hit_flash_material.tres")

@export var flash_time: float = 0.1
@export var sprite: CanvasItem
var instantiated_hitflash_material: ShaderMaterial

func _ready():
	instantiated_hitflash_material = hitflash_material_resource.duplicate()
	sprite.material = instantiated_hitflash_material

func flash() -> void:
	_set_flash(true)
	var timer = get_tree().create_timer(flash_time)
	timer.timeout.connect(func(): _set_flash(false))
	
func _set_flash(active: bool):
	instantiated_hitflash_material.set_shader_parameter("active", active)
